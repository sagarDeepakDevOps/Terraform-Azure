output "id" {
  description = "Managed Redis ID for a redisEnterprise private endpoint."
  value       = azurerm_managed_redis.this.id
}

output "hostname" {
  description = "Redis TLS hostname. Use the database port output instead of assuming legacy port 6380."
  value       = azurerm_managed_redis.this.hostname
}

output "port" {
  description = "Managed Redis database port."
  value       = azurerm_managed_redis.this.default_database[0].port
}

output "primary_access_key" {
  description = "Demo access key; stored in state. Prefer Entra authentication in production."
  value       = azurerm_managed_redis.this.default_database[0].primary_access_key
  sensitive   = true
}