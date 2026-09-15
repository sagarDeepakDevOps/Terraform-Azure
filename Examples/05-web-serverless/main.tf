resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  name = "${var.prefix}${random_id.suffix.hex}"
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
  address_space       = ["10.60.0.0/16"]
  subnets = {
    web = {
      address_prefixes = ["10.60.1.0/24"]
      delegation       = { name = "web", service_name = "Microsoft.Web/serverFarms" }
    }
    functions = {
      address_prefixes = ["10.60.2.0/24"]
      delegation       = { name = "flex", service_name = "Microsoft.App/environments" }
    }
    endpoints = { address_prefixes = ["10.60.3.0/24"] }
  }
  tags = var.tags
}

module "nat" {
  source              = "../../Modules/Vnet/NATGateway"
  name                = "${var.prefix}-nat"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_ids = {
    web       = module.network.subnet_ids["web"]
    functions = module.network.subnet_ids["functions"]
  }
  tags = var.tags
}

module "logs" {
  source              = "../../Modules/Monitoring/LogAnalytics"
  name                = "${var.prefix}-logs"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

module "insights" {
  source              = "../../Modules/Monitoring/ApplicationInsights"
  name                = "${var.prefix}-insights"
  resource_group_name = module.resource_group.name
  location            = var.location
  workspace_id        = module.logs.id
  tags                = var.tags
}

module "web" {
  source                = "../../Modules/AppService"
  name                  = "${local.name}-app"
  resource_group_name   = module.resource_group.name
  location              = var.location
  integration_subnet_id = module.network.subnet_ids["web"]
  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = module.insights.connection_string
  }
  tags = var.tags

  depends_on = [module.nat]
}

module "storage" {
  source              = "../../Modules/Storage"
  name                = "${local.name}func"
  resource_group_name = module.resource_group.name
  location            = var.location
  containers          = ["deployments"]
  tags                = var.tags
}

module "storage_dns" {
  source              = "../../Modules/Vnet/PrivateDNS"
  for_each            = toset(["blob", "queue", "table"])
  name                = "privatelink.${each.key}.core.windows.net"
  resource_group_name = module.resource_group.name
  virtual_network_ids = { web = module.network.id }
  tags                = var.tags
}

module "storage_endpoints" {
  source               = "../../Modules/Vnet/PrivateEndpoints"
  for_each             = toset(["blob", "queue", "table"])
  name                 = "${var.prefix}-${each.key}-pe"
  resource_group_name  = module.resource_group.name
  location             = var.location
  subnet_id            = module.network.subnet_ids["endpoints"]
  resource_id          = module.storage.id
  subresource_names    = [each.key]
  private_dns_zone_ids = [module.storage_dns[each.key].id]
  tags                 = var.tags
}

module "identity" {
  source              = "../../Modules/Identity"
  name                = "${var.prefix}-functions-identity"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

module "function_roles" {
  source = "../../Modules/RoleAssignments"
  assignments = {
    blob = {
      scope = module.storage.id, role = "Storage Blob Data Owner", principal_id = module.identity.principal_id
    }
    queue = {
      scope = module.storage.id, role = "Storage Queue Data Contributor", principal_id = module.identity.principal_id
    }
    table = {
      scope = module.storage.id, role = "Storage Table Data Contributor", principal_id = module.identity.principal_id
    }
    storage = {
      scope = module.storage.id, role = "Storage Account Contributor", principal_id = module.identity.principal_id
    }
  }
}

module "functions" {
  source                                 = "../../Modules/Functions"
  name                                   = "${local.name}-func"
  resource_group_name                    = module.resource_group.name
  location                               = var.location
  storage_account_name                   = module.storage.name
  storage_container_endpoint             = "${module.storage.blob_endpoint}deployments"
  identity_id                            = module.identity.id
  identity_client_id                     = module.identity.client_id
  integration_subnet_id                  = module.network.subnet_ids["functions"]
  application_insights_connection_string = module.insights.connection_string
  tags                                   = var.tags

  depends_on = [module.function_roles, module.storage_endpoints, module.nat]
}