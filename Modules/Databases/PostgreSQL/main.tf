terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Provision managed PostgreSQL 16 with private VNet integration.
# Creation: Azure uses the selected compute SKU, 32 GiB storage, seven-day backup
# retention and supplied password to create the pgadmin-managed server. The caller
# provides a subnet delegated to PostgreSQL and a service-compatible private DNS
# zone; the example explicitly waits for the zone's VNet link before this module.
# Security: Public access and Entra authentication are disabled in this demo, while
# password authentication is enabled. Use a TLS-capable private client and protect
# the administrator password in state. This is delegated-subnet access, not a PE.
# Important: No HA block is configured. Schema migrations, application users,
# restore testing and production authentication are separate responsibilities.
resource "azurerm_postgresql_flexible_server" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = "16"
  administrator_login           = "pgadmin"
  administrator_password        = var.administrator_password
  sku_name                      = var.sku_name
  storage_mb                    = 32768
  backup_retention_days         = 7
  delegated_subnet_id           = var.subnet_id
  private_dns_zone_id           = var.private_dns_zone_id
  public_network_access_enabled = false
  tags                          = var.tags

  authentication {
    password_auth_enabled         = true
    active_directory_auth_enabled = false
  }
}

# Purpose: Create the appdb logical database on the managed PostgreSQL server.
# Creation: AzureRM references the new server ID and requests UTF8 encoding with
# en_US.utf8 collation, so it runs after server provisioning through Azure's API.
# Important: This does not execute SQL migrations or insert data. Applications
# connect using the server FQDN, database name, TLS and appropriate database rights.
resource "azurerm_postgresql_flexible_server_database" "this" {
  name      = "appdb"
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}