output "id" {
  description = "Event Hubs namespace resource ID."
  value       = azurerm_eventhub_namespace.this.id
}

output "eventhub_id" {
  description = "Telemetry stream ID."
  value       = azurerm_eventhub.this.id
}

output "local_authentication_enabled" {
  description = "Whether local access keys are allowed."
  value       = azurerm_eventhub_namespace.this.local_authentication_enabled
}