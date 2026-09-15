output "id" {
  description = "Application Insights resource ID."
  value       = azurerm_application_insights.this.id
}

output "connection_string" {
  description = "SDK configuration value. Application instrumentation still needs to be deployed."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}