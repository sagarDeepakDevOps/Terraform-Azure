output "resource_group_name" {
  description = "State infrastructure resource group."
  value       = module.resource_group.name
}

output "storage_account_name" {
  description = "Account name for backend.hcl."
  value       = module.storage.name
}

output "container_name" {
  description = "Backend blob container."
  value       = "tfstate"
}

output "backend_authentication" {
  description = "Backend authentication settings; no account key is needed."
  value       = { use_azuread_auth = true }
}

output "storage_security" {
  description = "State storage security settings."
  value       = module.storage.security
}