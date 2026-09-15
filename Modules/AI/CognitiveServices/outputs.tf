output "id" {
  description = "AI account ID for RBAC and an account private endpoint."
  value       = azurerm_cognitive_account.this.id
}

output "endpoint" {
  description = "Private AI Services endpoint; use an Entra token."
  value       = azurerm_cognitive_account.this.endpoint
}