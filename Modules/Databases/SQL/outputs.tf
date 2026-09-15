output "id" {
  description = "Logical server ID for a sqlServer private endpoint."
  value       = azurerm_mssql_server.this.id
}

output "fqdn" {
  description = "SQL server FQDN. Use the normal FQDN, not the private endpoint IP, for TLS connections."
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "database_id" {
  description = "SQL database resource ID."
  value       = azurerm_mssql_database.this.id
}