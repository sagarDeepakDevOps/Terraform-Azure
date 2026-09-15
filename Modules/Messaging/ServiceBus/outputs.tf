output "id" {
  description = "Service Bus namespace resource ID."
  value       = azurerm_servicebus_namespace.this.id
}

output "queue_id" {
  description = "Orders queue ID for Event Grid delivery and scoped RBAC."
  value       = azurerm_servicebus_queue.this.id
}

output "local_auth_enabled" {
  description = "Whether shared access keys are allowed."
  value       = azurerm_servicebus_namespace.this.local_auth_enabled
}

output "endpoint" {
  description = "Service Bus namespace endpoint; use Entra token authentication."
  value       = azurerm_servicebus_namespace.this.endpoint
}