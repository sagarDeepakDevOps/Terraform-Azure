output "id" {
  description = "Workspace ARM ID for diagnostic settings and service integration."
  value       = azurerm_log_analytics_workspace.this.id
}

output "workspace_id" {
  description = "Workspace customer GUID, distinct from its ARM resource ID."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}