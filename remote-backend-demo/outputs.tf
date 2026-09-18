output "resource_group_names" {
  description = "Created group names keyed by short name."
  value       = { for key, group in module.resource_groups : key => group.name }
}

output "resource_group_ids" {
  description = "Created group resource IDs keyed by short name."
  value       = { for key, group in module.resource_groups : key => group.id }
}

# Repeated from backend.tf rather than shared with it, because a backend block
# cannot read a variable, a local or an output. See the README.
output "state_blob_name" {
  description = "Name of this configuration's state blob in the container, for the az storage commands in the README."
  value       = "remote-backend-demo.tfstate"
}
