data "azurerm_client_config" "current" {}

resource "random_id" "suffix" {
  byte_length = 3
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
  address_space       = ["10.70.0.0/16"]
  subnets = {
    aks = { address_prefixes = ["10.70.0.0/22"] }
    apps = {
      address_prefixes = ["10.70.4.0/23"]
      delegation       = { name = "apps", service_name = "Microsoft.App/environments" }
    }
  }
  tags = var.tags
}

module "nat" {
  source              = "../../Modules/Vnet/NATGateway"
  name                = "${var.prefix}-nat"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_ids          = module.network.subnet_ids
  tags                = var.tags
}

module "logs" {
  source              = "../../Modules/Monitoring/LogAnalytics"
  name                = "${var.prefix}-logs"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

module "registry" {
  source              = "../../Modules/ContainerRegistry"
  name                = "${var.prefix}${random_id.suffix.hex}acr"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

module "app_identity" {
  source              = "../../Modules/Identity"
  name                = "${var.prefix}-app-identity"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

module "app_roles" {
  source = "../../Modules/RoleAssignments"
  assignments = {
    pull = { scope = module.registry.id, role = "AcrPull", principal_id = module.app_identity.principal_id }
  }
}

module "apps" {
  source                     = "../../Modules/ContainerApps"
  name                       = "${var.prefix}-app"
  resource_group_name        = module.resource_group.name
  location                   = var.location
  subnet_id                  = module.network.subnet_ids["apps"]
  log_analytics_workspace_id = module.logs.id
  identity_id                = module.app_identity.id
  registry_server            = module.registry.login_server
  tags                       = var.tags

  depends_on = [module.app_roles, module.nat]
}

module "aks_identity" {
  source              = "../../Modules/Identity"
  count               = var.enable_aks ? 1 : 0
  name                = "${var.prefix}-aks-identity"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

module "aks_network_role" {
  source = "../../Modules/RoleAssignments"
  count  = var.enable_aks ? 1 : 0
  assignments = {
    network = {
      scope = module.network.id, role = "Network Contributor", principal_id = module.aks_identity[0].principal_id
    }
  }
}

module "aks" {
  source                     = "../../Modules/AKS"
  count                      = var.enable_aks ? 1 : 0
  name                       = "${var.prefix}-aks"
  resource_group_name        = module.resource_group.name
  location                   = var.location
  subnet_id                  = module.network.subnet_ids["aks"]
  identity_id                = module.aks_identity[0].id
  identity_principal_id      = module.aks_identity[0].principal_id
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  admin_group_object_ids     = var.aks_admin_group_object_ids
  log_analytics_workspace_id = module.logs.id
  registry_id                = module.registry.id
  tags                       = var.tags

  depends_on = [module.aks_network_role, module.nat]
}