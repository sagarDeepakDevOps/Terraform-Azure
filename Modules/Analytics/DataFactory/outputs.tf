output "id" {
  description = "Data Factory ID for a dataFactory private endpoint."
  value       = azurerm_data_factory.this.id
}

output "pipeline_name" {
  description = "Deployable pipeline name. No scheduled trigger is enabled."
  value       = azurerm_data_factory_pipeline.this.name
}