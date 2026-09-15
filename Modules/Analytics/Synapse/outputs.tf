output "id" {
  description = "Synapse workspace resource ID."
  value       = azurerm_synapse_workspace.this.id
}

output "connectivity_endpoints" {
  description = "Workspace endpoints; SQL, SqlOnDemand and Dev each need private connectivity."
  value       = azurerm_synapse_workspace.this.connectivity_endpoints
}