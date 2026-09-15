data "azurerm_client_config" "current" {}

resource "random_id" "suffix" {
  byte_length = 3
}

resource "random_password" "database" {
  length  = 24
  special = false
}

locals {
  name = "${var.prefix}${random_id.suffix.hex}"
  private_services = merge({
    blob  = { resource_id = module.storage.id, group = "blob", zone = "privatelink.blob.core.windows.net" }
    file  = { resource_id = module.storage.id, group = "file", zone = "privatelink.file.core.windows.net" }
    queue = { resource_id = module.storage.id, group = "queue", zone = "privatelink.queue.core.windows.net" }
    table = { resource_id = module.storage.id, group = "table", zone = "privatelink.table.core.windows.net" }
    vault = { resource_id = module.key_vault.id, group = "vault", zone = "privatelink.vaultcore.azure.net" }
    }, var.databases.sql ? {
    sql = { resource_id = module.sql[0].id, group = "sqlServer", zone = "privatelink.database.windows.net" }
    } : {}, var.databases.cosmos ? {
    cosmos = { resource_id = module.cosmos[0].id, group = "Sql", zone = "privatelink.documents.azure.com" }
    } : {}, var.databases.redis ? {
    redis = { resource_id = module.redis[0].id, group = "redisEnterprise", zone = "privatelink.redis.azure.net" }
  } : {})
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
  address_space       = ["10.50.0.0/16"]
  subnets = {
    endpoints = { address_prefixes = ["10.50.1.0/24"] }
    postgresql = {
      address_prefixes = ["10.50.2.0/24"]
      delegation       = { name = "postgresql", service_name = "Microsoft.DBforPostgreSQL/flexibleServers" }
    }
    mysql = {
      address_prefixes = ["10.50.3.0/24"]
      delegation       = { name = "mysql", service_name = "Microsoft.DBforMySQL/flexibleServers" }
    }
  }
  tags = var.tags
}

module "storage" {
  source                  = "../../Modules/Storage"
  name                    = "${local.name}st"
  resource_group_name     = module.resource_group.name
  location                = var.location
  containers              = ["data", "documents"]
  file_shares             = { shared = 50 }
  queues                  = ["jobs"]
  tables                  = ["DemoEvents"]
  enable_lifecycle_policy = true
  tags                    = var.tags
}

module "identity" {
  source              = "../../Modules/Identity"
  name                = "${var.prefix}-app-identity"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

module "key_vault" {
  source              = "../../Modules/KeyVault"
  name                = "${local.name}-kv"
  resource_group_name = module.resource_group.name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = var.tags
}

module "roles" {
  source = "../../Modules/RoleAssignments"
  assignments = {
    blob = {
      scope = module.storage.id, role = "Storage Blob Data Contributor", principal_id = module.identity.principal_id
    }
    secrets = {
      scope = module.key_vault.id, role = "Key Vault Secrets User", principal_id = module.identity.principal_id
    }
  }
}

module "sql" {
  source                 = "../../Modules/Databases/SQL"
  count                  = var.databases.sql ? 1 : 0
  name                   = "${local.name}-sql"
  resource_group_name    = module.resource_group.name
  location               = var.location
  administrator_password = random_password.database.result
  tags                   = var.tags
}

module "private_dns" {
  source              = "../../Modules/Vnet/PrivateDNS"
  for_each            = local.private_services
  name                = each.value.zone
  resource_group_name = module.resource_group.name
  virtual_network_ids = { data = module.network.id }
  tags                = var.tags
}

module "private_endpoints" {
  source               = "../../Modules/Vnet/PrivateEndpoints"
  for_each             = local.private_services
  name                 = "${var.prefix}-${each.key}-pe"
  resource_group_name  = module.resource_group.name
  location             = var.location
  subnet_id            = module.network.subnet_ids["endpoints"]
  resource_id          = each.value.resource_id
  subresource_names    = [each.value.group]
  private_dns_zone_ids = [module.private_dns[each.key].id]
  tags                 = var.tags
}

module "postgresql_dns" {
  source              = "../../Modules/Vnet/PrivateDNS"
  count               = var.databases.postgresql ? 1 : 0
  name                = "${local.name}.postgres.database.azure.com"
  resource_group_name = module.resource_group.name
  virtual_network_ids = { data = module.network.id }
  tags                = var.tags
}

module "postgresql" {
  source                 = "../../Modules/Databases/PostgreSQL"
  count                  = var.databases.postgresql ? 1 : 0
  name                   = "${local.name}-pg"
  resource_group_name    = module.resource_group.name
  location               = var.location
  administrator_password = random_password.database.result
  subnet_id              = module.network.subnet_ids["postgresql"]
  private_dns_zone_id    = module.postgresql_dns[0].id
  tags                   = var.tags

  depends_on = [module.postgresql_dns]
}

module "mysql_dns" {
  source              = "../../Modules/Vnet/PrivateDNS"
  count               = var.databases.mysql ? 1 : 0
  name                = "${local.name}.mysql.database.azure.com"
  resource_group_name = module.resource_group.name
  virtual_network_ids = { data = module.network.id }
  tags                = var.tags
}

module "mysql" {
  source                 = "../../Modules/Databases/MySQL"
  count                  = var.databases.mysql ? 1 : 0
  name                   = "${local.name}-mysql"
  resource_group_name    = module.resource_group.name
  location               = var.location
  administrator_password = random_password.database.result
  subnet_id              = module.network.subnet_ids["mysql"]
  private_dns_zone_id    = module.mysql_dns[0].id
  tags                   = var.tags

  depends_on = [module.mysql_dns]
}

module "cosmos" {
  source              = "../../Modules/Databases/CosmosDB"
  count               = var.databases.cosmos ? 1 : 0
  name                = "${local.name}-cosmos"
  resource_group_name = module.resource_group.name
  location            = var.location
  principal_id        = module.identity.principal_id
  tags                = var.tags
}

module "redis" {
  source              = "../../Modules/Databases/ManagedRedis"
  count               = var.databases.redis ? 1 : 0
  name                = "${local.name}-redis"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}