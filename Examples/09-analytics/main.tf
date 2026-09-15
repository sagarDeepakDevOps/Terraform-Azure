resource "random_id" "suffix" {
  byte_length = 3
}

resource "random_password" "synapse" {
  length           = 24
  special          = true
  override_special = "!@#%_-+="
}

locals {
  name = "${var.prefix}${random_id.suffix.hex}"
  private_services = merge({
    blob = { id = module.lake.id, group = "blob", zone = "privatelink.blob.core.windows.net" }
    dfs  = { id = module.lake.id, group = "dfs", zone = "privatelink.dfs.core.windows.net" }
    adf  = { id = module.factory.id, group = "dataFactory", zone = "privatelink.datafactory.azure.net" }
    }, var.enable_synapse ? {
    sql        = { id = module.synapse[0].id, group = "Sql", zone = "privatelink.sql.azuresynapse.net" }
    serverless = { id = module.synapse[0].id, group = "SqlOnDemand", zone = "privatelink.sql.azuresynapse.net" }
    dev        = { id = module.synapse[0].id, group = "Dev", zone = "privatelink.dev.azuresynapse.net" }
  } : {})
  private_zones = toset([for service in values(local.private_services) : service.zone])
}

module "resource_group" {
  source   = "../../Modules/ResourceGroups"
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

module "network" {
  source              = "../../Modules/Vnet"
  name                = "${var.prefix}-vnet"
  resource_group_name = module.resource_group.name
  location            = var.location
  address_space       = ["10.100.0.0/16"]
  subnets = {
    endpoints = { address_prefixes = ["10.100.1.0/24"] }
    dbhost = {
      address_prefixes = ["10.100.2.0/24"]
      delegation = {
        name    = "databricks", service_name = "Microsoft.Databricks/workspaces"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
      }
    }
    dbcontainer = {
      address_prefixes = ["10.100.3.0/24"]
      delegation = {
        name    = "databricks", service_name = "Microsoft.Databricks/workspaces"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
      }
    }
  }
  tags = var.tags
}

module "lake" {
  source                         = "../../Modules/Storage"
  name                           = "${local.name}lake"
  resource_group_name            = module.resource_group.name
  location                       = var.location
  hierarchical_namespace_enabled = true
  containers                     = ["raw", "curated", "synapse"]
  tags                           = var.tags
}

module "factory" {
  source               = "../../Modules/Analytics/DataFactory"
  name                 = "${local.name}-adf"
  resource_group_name  = module.resource_group.name
  location             = var.location
  storage_account_id   = module.lake.id
  storage_dfs_endpoint = module.lake.dfs_endpoint
  tags                 = var.tags
}

module "synapse" {
  source                 = "../../Modules/Analytics/Synapse"
  count                  = var.enable_synapse ? 1 : 0
  name                   = "${local.name}-syn"
  resource_group_name    = module.resource_group.name
  location               = var.location
  storage_account_id     = module.lake.id
  filesystem_id          = "${module.lake.dfs_endpoint}synapse"
  administrator_password = random_password.synapse.result
  tags                   = var.tags

  depends_on = [module.lake]
}

module "private_dns" {
  source              = "../../Modules/Vnet/PrivateDNS"
  for_each            = local.private_zones
  name                = each.value
  resource_group_name = module.resource_group.name
  virtual_network_ids = { analytics = module.network.id }
  tags                = var.tags
}

module "private_endpoints" {
  source               = "../../Modules/Vnet/PrivateEndpoints"
  for_each             = local.private_services
  name                 = "${var.prefix}-${each.key}-pe"
  resource_group_name  = module.resource_group.name
  location             = var.location
  subnet_id            = module.network.subnet_ids["endpoints"]
  resource_id          = each.value.id
  subresource_names    = [each.value.group]
  private_dns_zone_ids = [module.private_dns[each.value.zone].id]
  tags                 = var.tags
}

resource "azurerm_synapse_managed_private_endpoint" "lake" {
  for_each             = var.configure_synapse_managed_endpoints ? toset(["blob", "dfs"]) : toset([])
  name                 = "lake-${each.key}"
  synapse_workspace_id = module.synapse[0].id
  target_resource_id   = module.lake.id
  subresource_name     = each.key

  depends_on = [module.private_endpoints]
}

module "databricks_nsg" {
  source              = "../../Modules/Vnet/NSG"
  count               = var.enable_databricks ? 1 : 0
  name                = "${var.prefix}-db-nsg"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_ids = {
    dbhost      = module.network.subnet_ids["dbhost"]
    dbcontainer = module.network.subnet_ids["dbcontainer"]
  }
  tags = var.tags
}

module "databricks_nat" {
  source              = "../../Modules/Vnet/NATGateway"
  count               = var.enable_databricks ? 1 : 0
  name                = "${var.prefix}-db-nat"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_ids = {
    dbhost      = module.network.subnet_ids["dbhost"]
    dbcontainer = module.network.subnet_ids["dbcontainer"]
  }
  tags = var.tags
}

module "databricks" {
  source                     = "../../Modules/Analytics/Databricks"
  count                      = var.enable_databricks ? 1 : 0
  name                       = "${local.name}-db"
  resource_group_name        = module.resource_group.name
  location                   = var.location
  virtual_network_id         = module.network.id
  public_subnet_name         = "dbhost"
  private_subnet_name        = "dbcontainer"
  public_nsg_association_id  = module.databricks_nsg[0].association_ids["dbhost"]
  private_nsg_association_id = module.databricks_nsg[0].association_ids["dbcontainer"]
  storage_account_id         = module.lake.id
  tags                       = var.tags

  depends_on = [module.databricks_nat]
}