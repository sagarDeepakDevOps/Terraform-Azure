output "id" {
  description = "Web App resource ID."
  value       = azurerm_linux_web_app.this.id
}

output "hostname" {
  description = "Default Web App hostname."
  value       = azurerm_linux_web_app.this.default_hostname
}

output "principal_id" {
  description = "System-assigned application identity principal ID."
  value       = azurerm_linux_web_app.this.identity[0].principal_id
}

output "https_only" {
  description = "Whether HTTPS is enforced."
  value       = azurerm_linux_web_app.this.https_only
}