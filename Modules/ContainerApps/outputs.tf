output "id" {
  description = "Container App resource ID."
  value       = azurerm_container_app.this.id
}

output "hostname" {
  description = "Container App HTTPS ingress hostname."
  value       = azurerm_container_app.this.ingress[0].fqdn
}