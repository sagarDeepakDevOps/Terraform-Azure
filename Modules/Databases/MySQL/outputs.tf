output "id" {
  description = "MySQL Flexible Server ID."
  value       = azurerm_mysql_flexible_server.this.id
}

output "fqdn" {
  description = "Private MySQL FQDN, port 3306 with TLS."
  value       = azurerm_mysql_flexible_server.this.fqdn
}