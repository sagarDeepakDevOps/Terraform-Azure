output "data_factory_pipeline" {
  description = "Small demonstration pipeline. Approve storage managed endpoints before extending it to data movement."
  value       = module.factory.pipeline_name
}

output "lake_filesystems" {
  description = "Data lake filesystem names."
  value       = keys(module.lake.container_ids)
}

output "optional_platforms" {
  description = "Optional analytics platform selection."
  value       = { synapse = var.enable_synapse, databricks = var.enable_databricks }
}

output "databricks_url" {
  description = "Optional authenticated workspace UI."
  value       = var.enable_databricks ? "https://${module.databricks[0].workspace_url}" : null
}