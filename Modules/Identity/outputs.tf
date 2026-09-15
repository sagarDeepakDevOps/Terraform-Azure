output "id" {
  description = "Managed identity resource ID for attachment to Azure services."
  value       = azurerm_user_assigned_identity.this.id
}

output "principal_id" {
  description = "Service principal object ID for RBAC."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "client_id" {
  description = "Client ID used by application managed identity authentication."
  value       = azurerm_user_assigned_identity.this.client_id
}