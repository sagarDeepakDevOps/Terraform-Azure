data "azurerm_client_config" "current" {}

resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  name = "${var.prefix}${random_id.suffix.hex}"
  private_services = merge({
    cognitive = { id = module.cognitive.id, group = "account", zones = ["privatelink.cognitiveservices.azure.com"] }
    search    = { id = module.search.id, group = "searchService", zones = ["privatelink.search.windows.net"] }
    }, var.enable_openai ? {
    openai = { id = module.openai[0].id, group = "account", zones = ["privatelink.openai.azure.com"] }
    } : {}, var.enable_machine_learning ? {
    ml    = { id = module.machine_learning[0].id, group = "amlworkspace", zones = ["privatelink.api.azureml.ms", "privatelink.notebooks.azure.net"] }
    blob  = { id = module.ml_storage[0].id, group = "blob", zones = ["privatelink.blob.core.windows.net"] }
    file  = { id = module.ml_storage[0].id, group = "file", zones = ["privatelink.file.core.windows.net"] }
    vault = { id = module.ml_vault[0].id, group = "vault", zones = ["privatelink.vaultcore.azure.net"] }
  } : {})
  private_zones = toset(flatten([for service in values(local.private_services) : service.zones]))
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
  address_space       = ["10.110.0.0/16"]
  subnets = {
    endpoints = { address_prefixes = ["10.110.1.0/24"] }
  }
  tags = var.tags
}

module "identity" {
  source              = "../../Modules/Identity"
  name                = "${var.prefix}-app-identity"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

module "cognitive" {
  source              = "../../Modules/AI/CognitiveServices"
  name                = "${local.name}-cog"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

module "search" {
  source              = "../../Modules/AI/Search"
  name                = "${local.name}-search"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

module "openai" {
  source              = "../../Modules/AI/OpenAI"
  count               = var.enable_openai ? 1 : 0
  name                = "${local.name}-openai"
  resource_group_name = module.resource_group.name
  location            = var.location
  deployments         = var.openai_deployments
  tags                = var.tags
}

module "ai_roles" {
  source = "../../Modules/RoleAssignments"
  assignments = merge({
    cognitive = { scope = module.cognitive.id, role = "Cognitive Services User", principal_id = module.identity.principal_id }
    search    = { scope = module.search.id, role = "Search Index Data Contributor", principal_id = module.identity.principal_id }
    }, var.enable_openai ? {
    openai = { scope = module.openai[0].id, role = "Cognitive Services OpenAI User", principal_id = module.identity.principal_id }
  } : {})
}

module "ml_storage" {
  source              = "../../Modules/Storage"
  count               = var.enable_machine_learning ? 1 : 0
  name                = "${local.name}ml"
  resource_group_name = module.resource_group.name
  location            = var.location
  containers          = ["datasets", "artifacts"]
  tags                = var.tags
}

module "ml_vault" {
  source              = "../../Modules/KeyVault"
  count               = var.enable_machine_learning ? 1 : 0
  name                = "${local.name}-mlkv"
  resource_group_name = module.resource_group.name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = var.tags
}

module "ml_logs" {
  source              = "../../Modules/Monitoring/LogAnalytics"
  count               = var.enable_machine_learning ? 1 : 0
  name                = "${var.prefix}-ml-logs"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

module "ml_insights" {
  source              = "../../Modules/Monitoring/ApplicationInsights"
  count               = var.enable_machine_learning ? 1 : 0
  name                = "${var.prefix}-ml-insights"
  resource_group_name = module.resource_group.name
  location            = var.location
  workspace_id        = module.ml_logs[0].id
  tags                = var.tags
}

module "ml_identity" {
  source              = "../../Modules/Identity"
  count               = var.enable_machine_learning ? 1 : 0
  name                = "${var.prefix}-ml-identity"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

module "ml_roles" {
  source = "../../Modules/RoleAssignments"
  count  = var.enable_machine_learning ? 1 : 0
  assignments = {
    blobs    = { scope = module.ml_storage[0].id, role = "Storage Blob Data Contributor", principal_id = module.ml_identity[0].principal_id }
    files    = { scope = module.ml_storage[0].id, role = "Storage File Data Privileged Contributor", principal_id = module.ml_identity[0].principal_id }
    storage  = { scope = module.ml_storage[0].id, role = "Storage Account Contributor", principal_id = module.ml_identity[0].principal_id }
    secrets  = { scope = module.ml_vault[0].id, role = "Key Vault Secrets Officer", principal_id = module.ml_identity[0].principal_id }
    vault    = { scope = module.ml_vault[0].id, role = "Key Vault Contributor", principal_id = module.ml_identity[0].principal_id }
    insights = { scope = module.ml_insights[0].id, role = "Monitoring Contributor", principal_id = module.ml_identity[0].principal_id }
  }
}

module "machine_learning" {
  source                  = "../../Modules/AI/MachineLearning"
  count                   = var.enable_machine_learning ? 1 : 0
  name                    = "${local.name}-ml"
  resource_group_name     = module.resource_group.name
  location                = var.location
  storage_account_id      = module.ml_storage[0].id
  key_vault_id            = module.ml_vault[0].id
  application_insights_id = module.ml_insights[0].id
  identity_id             = module.ml_identity[0].id
  tags                    = var.tags

  depends_on = [module.ml_roles]
}

module "private_dns" {
  source              = "../../Modules/Vnet/PrivateDNS"
  for_each            = local.private_zones
  name                = each.value
  resource_group_name = module.resource_group.name
  virtual_network_ids = { ai = module.network.id }
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
  private_dns_zone_ids = [for zone in each.value.zones : module.private_dns[zone].id]
  tags                 = var.tags
}