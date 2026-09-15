terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Provision an Azure-managed MySQL Flexible Server on private networking.
# Creation: AzureRM uses the selected SKU, 20 GiB auto-growing storage, seven-day
# backup retention and supplied mysqladmin password. The caller provides a subnet
# delegated to MySQL and a linked private DNS zone; public access stays Disabled.
# Version: 8.0.21 is the Azure API's MySQL 8.0 selector, not a promise that Azure's
# current managed patch level remains exactly that historical version.
# Important: The password is stored in state. No HA or application schema is
# configured, auto-growing storage can increase costs, and private clients still
# need a working route, DNS, TLS and database authentication.
resource "azurerm_mysql_flexible_server" "this" {
  name                   = var.name
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = "8.0.21"
  administrator_login    = "mysqladmin"
  administrator_password = var.administrator_password
  sku_name               = var.sku_name
  backup_retention_days  = 7
  delegated_subnet_id    = var.subnet_id
  private_dns_zone_id    = var.private_dns_zone_id
  public_network_access  = "Disabled"
  tags                   = var.tags

  storage {
    size_gb           = 20
    auto_grow_enabled = true
  }
}

# Purpose: Create the application's MySQL database after the server is provisioned.
# Creation: Reference the new server name and request appdb with utf8mb4 encoding
# and utf8mb4_unicode_ci collation, supporting full Unicode application text.
# Important: This creates database metadata only. Tables, migrations, application
# users and their grants must be deployed separately by the application owner.
resource "azurerm_mysql_flexible_database" "this" {
  name                = "appdb"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.this.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# Purpose: Require clients to use encrypted transport when connecting to MySQL.
# Creation: AzureRM sets the require_secure_transport server parameter to ON on
# the server created above; its name reference provides the ordering dependency.
# Important: Private networking is not a substitute for TLS. Configure the client
# to validate the service certificate and connect using the normal server FQDN.
resource "azurerm_mysql_flexible_server_configuration" "tls" {
  name                = "require_secure_transport"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.this.name
  value               = "ON"
}