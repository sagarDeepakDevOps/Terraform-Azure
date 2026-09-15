output "id" {
  description = "Registry ID for AcrPull/AcrPush grants."
  value       = azurerm_container_registry.this.id
}

output "login_server" {
  description = "Authenticated container registry hostname."
  value       = azurerm_container_registry.this.login_server
}

output "admin_enabled" {
  description = "Whether the shared registry administrator credential is enabled."
  value       = azurerm_container_registry.this.admin_enabled
}