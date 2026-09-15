terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create a Cosmos DB for NoSQL account for document-oriented application data.
# Creation: Azure provisions one serverless region, Session consistency and periodic
# locally redundant backups taken every four hours with eight-hour retention.
# GlobalDocumentDB is the provider's account kind for this NoSQL API; the child
# database/container resources below do not represent a relational SQL Server.
# Security: Require TLS 1.2 and disable public networking and local keys. The caller
# supplies private endpoint/DNS access and a workload identity for a data-role grant.
# Important: Serverless usage is billable. One configured region and periodic
# backups are demo choices, not a multi-region availability or recovery design.
resource "azurerm_cosmosdb_account" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  offer_type                    = "Standard"
  kind                          = "GlobalDocumentDB"
  public_network_access_enabled = false
  local_authentication_enabled  = false
  minimal_tls_version           = "Tls12"
  tags                          = var.tags

  capabilities {
    name = "EnableServerless"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  backup {
    type                = "Periodic"
    interval_in_minutes = 240
    retention_in_hours  = 8
    storage_redundancy  = "Local"
  }
}

# Purpose: Group the application's NoSQL containers under a logical appdb database.
# Creation: AzureRM references the newly created Cosmos account name, which orders
# database creation after the account. No provisioned RU/s is set for this serverless
# account; the container below defines how documents are partitioned.
# Important: A database alone stores no documents and grants no application access.
resource "azurerm_cosmosdb_sql_database" "this" {
  name                = "appdb"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
}

# Purpose: Create the items container where application JSON documents are stored.
# Creation: Reference the account and database, then configure a version-2 partition
# key on /tenantId. Application documents and queries must use that chosen key so
# Cosmos can distribute and locate data efficiently.
# Important: A partition key is a data-model/performance decision, not an automatic
# tenant authorization boundary. This block inserts no documents and changes to
# partitioning may require a new container and an explicit data migration.
resource "azurerm_cosmosdb_sql_container" "this" {
  name                  = "items"
  resource_group_name   = var.resource_group_name
  account_name          = azurerm_cosmosdb_account.this.name
  database_name         = azurerm_cosmosdb_sql_database.this.name
  partition_key_paths   = ["/tenantId"]
  partition_key_version = 2
}

# Purpose: Authorize the application's Entra identity to access Cosmos NoSQL data.
# Creation: Assign the built-in NoSQL Data Contributor definition ending in 0002
# to var.principal_id at account scope after the account exists. This is Cosmos's
# data-plane RBAC resource, not an ordinary Azure management-plane role assignment.
# Important: The principal must exist and clients need a token plus private network
# access. Account scope covers its databases/containers; narrow scope where needed
# for a production workload instead of relying on the document partition key.
resource "azurerm_cosmosdb_sql_role_assignment" "this" {
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  role_definition_id  = "${azurerm_cosmosdb_account.this.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = var.principal_id
  scope               = azurerm_cosmosdb_account.this.id
}