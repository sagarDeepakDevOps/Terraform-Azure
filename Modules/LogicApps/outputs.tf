output "id" {
  description = "Logic App workflow resource ID."
  value       = azurerm_logic_app_workflow.this.id
}

output "enabled" {
  description = "Whether scheduled executions are enabled."
  value       = azurerm_logic_app_workflow.this.enabled
}