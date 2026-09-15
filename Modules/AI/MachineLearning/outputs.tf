output "id" {
  description = "Machine Learning workspace ID for an amlworkspace private endpoint."
  value       = azurerm_machine_learning_workspace.this.id
}

output "storage_account_access_type" {
  description = "How the workspace authenticates to its system storage account."
  value       = azurerm_machine_learning_workspace.this.storage_account_access_type
}