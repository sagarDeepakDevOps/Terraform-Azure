terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create the logical Azure SQL server that hosts managed SQL databases.
# Creation: AzureRM provisions the globally named service in the selected region,
# initializes the supplied SQL administrator and requires TLS 1.2. The 12.0 value
# is Azure SQL's logical-server version selector; this does not install SQL on a VM.
# Security: Public network access is disabled. The caller must create a sqlServer
# private endpoint, matching DNS and a reachable authorized client before use.
# Important: The administrator password remains in Terraform state. Production
# should use an intentional Entra/database authentication model and least-privilege
# application users, not distribute the administrator credential to applications.
resource "azurerm_mssql_server" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = "12.0"
  administrator_login           = var.administrator_login
  administrator_login_password  = var.administrator_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  tags                          = var.tags
}

# Purpose: Create the application database under the logical server above.
# Creation: The server_id reference orders database creation after the server. The
# caller selects a compatible compute SKU and maximum data size; locally redundant
# backup storage and seven-day short-term recovery retention are configured here.
# Important: This provisions an empty database, not schemas, tables, users or seed
# data. Review SKU/size limits and recovery needs; Basic demo settings are not a
# production performance, high-availability or cross-region recovery commitment.
resource "azurerm_mssql_database" "this" {
  name                 = var.database_name
  server_id            = azurerm_mssql_server.this.id
  sku_name             = var.sku_name
  max_size_gb          = var.max_size_gb
  storage_account_type = "Local"
  tags                 = var.tags

  short_term_retention_policy {
    retention_days = 7
  }
}