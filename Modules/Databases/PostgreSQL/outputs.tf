output "id" {
  description = "PostgreSQL Flexible Server ID."
  value       = azurerm_postgresql_flexible_server.this.id
}

output "fqdn" {
  description = "Private PostgreSQL FQDN, port 5432 with TLS."
  value       = azurerm_postgresql_flexible_server.this.fqdn
}