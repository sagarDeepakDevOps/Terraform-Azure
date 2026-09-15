# Purpose: Read the tenant context used by the authenticated root AzureRM provider.
# Creation: This data source creates no identity/resource; its tenant_id places
# the Key Vault in the correct Entra tenant. Tests replace it with a mock value.
data "azurerm_client_config" "current" {}

# Purpose: Keep globally named services distinct across separate copies of the demo.
# Creation: Random generates three bytes locally and exposes a six-character hex
# suffix, retained in this root's state and reused by the naming local below.
# Important: It is not an Azure resource or a guarantee of global name availability.
resource "random_id" "suffix" {
  byte_length = 3
}

# Purpose: Generate the demo administrator password without committing it in source.
# Creation: The Random provider generates a 24-character alphanumeric value locally;
# selected SQL/PostgreSQL/MySQL modules all consume this same state-retained result.
# Important: It is sensitive, not absent from state. Sharing one administrator
# password is a teaching simplification; production needs separate identities/users
# or credentials, rotation and a protected state/secret-handling process.
resource "random_password" "database" {
  length  = 24
  special = false
}

# Purpose: Derive one naming prefix and the exact private-endpoint/DNS service map.
# Evaluation: merge always includes Storage/Key Vault, then includes SQL, Cosmos or
# Redis only when their boolean is true. Each entry couples a resource ID, Azure
# subresource name and correct private DNS zone; keys stay known during planning.
# Important: PostgreSQL/MySQL instead use delegated subnets below. Turning an enabled
# database flag off later plans deletion of its module/endpoints, not service suspension.
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

# Purpose: Own this independent data lab's storage, databases, identity and networking.
# Creation: Create the group once and pass its output name to all related modules.
module "resource_group" {
  source   = "../../Modules/ResourceGroups"
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# Purpose: Separate ordinary private endpoints from PostgreSQL/MySQL subnet injection.
# Creation: Build 10.50.0.0/16 with an undelegated endpoint subnet and two distinct
# database subnets delegated to their respective Azure services. Outputs expose all IDs.
# Important: This creates no VPN/jump host. Data clients still need an authorized
# route and DNS path into this private lab network.
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

# Purpose: Demonstrate Blob, Files, Queues and Tables within one private storage account.
# Creation: The Storage module creates data/documents containers, a 50-GiB-quota SMB
# share, jobs queue and DemoEvents Table after the resource group exists.
# Important: Lifecycle rules are enabled for data/ blobs and can eventually delete
# matching data. Shared keys remain disabled; SMB identity/domain setup and actual
# application data are not created by this storage module call.
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

# Purpose: Create an application identity for the demonstration's scoped data grants.
# Creation: The Identity module returns ARM/client/principal IDs after group creation.
# Important: No application is attached to the identity automatically in this lab.
module "identity" {
  source              = "../../Modules/Identity"
  name                = "${var.prefix}-app-identity"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

# Purpose: Create a private, RBAC-authorized and purge-protected vault for this data lab.
# Creation: Combine the generated service name, group output and current tenant ID.
# Important: This creates no secret values. A matching private endpoint and role
# grants are configured below; deletion/name reuse remains subject to retention.
module "key_vault" {
  source              = "../../Modules/KeyVault"
  name                = "${local.name}-kv"
  resource_group_name = module.resource_group.name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = var.tags
}

# Purpose: Give the application identity Blob write/read and Key Vault secret-read rights.
# Creation: Pass explicit role/scope/principal triples derived from created resource
# outputs; Terraform waits for the storage, vault and identity before assigning roles.
# Important: These Azure data grants neither open network paths nor create database
# users. The caller also needs permission to create role assignments at these scopes.
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

# Purpose: Deploy the optional Azure SQL server/database selected by databases.sql.
# Creation: count controls a single module instance, using the generated demo
# password. The private-services map above consumes its server ID only when enabled.
# Important: SQL has independent cost and requires private connectivity plus migrations.
module "sql" {
  source                 = "../../Modules/Databases/SQL"
  count                  = var.databases.sql ? 1 : 0
  name                   = "${local.name}-sql"
  resource_group_name    = module.resource_group.name
  location               = var.location
  administrator_password = random_password.database.result
  tags                   = var.tags
}

# Purpose: Create and VNet-link the DNS zone required by each selected endpoint service.
# Creation: for_each uses the same stable private_services keys as the endpoint loop,
# ensuring a matching zone ID can be retrieved by each.key after zone creation.
# Important: Links cover this VNet only; connected client VNets need deliberate DNS design.
module "private_dns" {
  source              = "../../Modules/Vnet/PrivateDNS"
  for_each            = local.private_services
  name                = each.value.zone
  resource_group_name = module.resource_group.name
  virtual_network_ids = { data = module.network.id }
  tags                = var.tags
}

# Purpose: Give each selected service an address on the endpoint subnet and private DNS.
# Creation: Pair each service's ARM ID/group with its corresponding newly created zone
# ID and the network's endpoint subnet. Resource references form the deployment graph.
# Important: Endpoints do not grant data access; public access is disabled separately
# by the underlying service modules, and real clients still need routing/DNS/authentication.
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

# Purpose: Prepare PostgreSQL Flexible Server's delegated-network DNS zone when selected.
# Creation: count follows databases.postgresql and links a service-compatible zone to
# the lab VNet before the database module's explicit dependency is satisfied.
module "postgresql_dns" {
  source              = "../../Modules/Vnet/PrivateDNS"
  count               = var.databases.postgresql ? 1 : 0
  name                = "${local.name}.postgres.database.azure.com"
  resource_group_name = module.resource_group.name
  virtual_network_ids = { data = module.network.id }
  tags                = var.tags
}

# Purpose: Optionally create PostgreSQL in its own delegated subnet rather than via PE.
# Creation: Pass the generated password, PostgreSQL subnet and matching zone ID.
# depends_on waits for the entire DNS module, including its VNet link, not just the zone.
# Important: The server uses demo authentication/capacity and creates no application schema.
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

# Purpose: Prepare the separate MySQL delegated-network DNS namespace when selected.
# Creation: count follows databases.mysql, creates a compatible zone and links the VNet.
# The MySQL module explicitly waits for this full zone/link configuration.
module "mysql_dns" {
  source              = "../../Modules/Vnet/PrivateDNS"
  count               = var.databases.mysql ? 1 : 0
  name                = "${local.name}.mysql.database.azure.com"
  resource_group_name = module.resource_group.name
  virtual_network_ids = { data = module.network.id }
  tags                = var.tags
}

# Purpose: Optionally create MySQL Flexible Server on its dedicated delegated subnet.
# Creation: Reuse the generated demo password and pass the matching subnet/zone IDs;
# depends_on ensures the DNS link exists before Azure provisions the server.
# Important: This is private subnet injection, not the generic endpoint loop above.
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

# Purpose: Optionally create serverless Cosmos NoSQL with identity-based data access.
# Creation: count follows databases.cosmos; the module creates account/database/container
# and grants the existing app identity its Cosmos data role. The map adds its PE/DNS.
# Important: No documents are seeded and the demo is single-region, not a DR design.
module "cosmos" {
  source              = "../../Modules/Databases/CosmosDB"
  count               = var.databases.cosmos ? 1 : 0
  name                = "${local.name}-cosmos"
  resource_group_name = module.resource_group.name
  location            = var.location
  principal_id        = module.identity.principal_id
  tags                = var.tags
}

# Purpose: Optionally provision Azure Managed Redis as a private demonstration cache.
# Creation: count follows databases.redis; its account ID is joined to the matching
# redisEnterprise endpoint/DNS entry. Hostname and port are exported after deployment.
# Important: This module is non-HA, uses sensitive demo access keys and has idle costs.
module "redis" {
  source              = "../../Modules/Databases/ManagedRedis"
  count               = var.databases.redis ? 1 : 0
  name                = "${local.name}-redis"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}