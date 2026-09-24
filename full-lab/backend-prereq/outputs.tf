output "state_resource_group_name" {
  description = "Resource group holding the state account. Separate from the lab group on purpose."
  value       = module.resource_group.name
}

output "storage_account_name" {
  description = "Generated storage account name. Goes into every backend block."
  value       = module.tfstate.storage_account_name
}

output "container_name" {
  description = "Container each configuration writes its state blob into."
  value       = module.tfstate.container_name
}

output "backend_config_file" {
  description = "Path to the generated partial backend configuration, or null when write_backend_config_file is false."
  value       = one(local_file.backend_config[*].filename)
}

output "backend_hcl" {
  description = "Contents of the partial backend configuration, in case you would rather paste it than use the file."
  value       = module.tfstate.backend_hcl
}
