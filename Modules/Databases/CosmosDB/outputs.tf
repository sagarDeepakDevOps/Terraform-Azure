output "id" {
  description = "Cosmos account ID for a Sql private endpoint."
  value       = azurerm_cosmosdb_account.this.id
}

output "endpoint" {
  description = "NoSQL endpoint. Use managed identity authentication."
  value       = azurerm_cosmosdb_account.this.endpoint
}