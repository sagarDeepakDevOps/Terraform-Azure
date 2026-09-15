output "id" {
  description = "Databricks workspace resource ID."
  value       = azurerm_databricks_workspace.this.id
}

output "workspace_url" {
  description = "Authenticated public workspace UI. Private UI/SSO endpoints are a separate production design."
  value       = azurerm_databricks_workspace.this.workspace_url
}

output "access_connector_id" {
  description = "Managed identity access connector for a Unity Catalog storage credential."
  value       = azurerm_databricks_access_connector.this.id
}