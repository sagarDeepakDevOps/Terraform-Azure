output "state_resource_group_name" {
  description = "Resource group holding the state account. Separate from hub-spoke's group on purpose."
  value       = module.resource_group.name
}

output "storage_account_name" {
  description = "Generated storage account name."
  value       = module.tfstate.storage_account_name
}

output "container_name" {
  description = "Container hub-spoke writes its state blob into."
  value       = module.tfstate.container_name
}

output "backend_config_file" {
  description = "Path of the generated backend.hcl, or null when write_backend_config_file is false."
  value       = one(local_file.backend_config[*].filename)
}

output "backend_hcl" {
  description = "Contents of backend.hcl, to paste or to regenerate the file: terraform output -raw backend_hcl > ../backend.hcl"
  value       = module.tfstate.backend_hcl
}
