# Outputs expose selected child-module values after deployment. IDs can be reused
# in a deliberate larger composition; printing them does not grant access to Azure.
# No credentials, private keys or application connection strings are exported here.

output "resource_group_name" {
  description = "Resource group created by the root starter."
  value       = module.resource_group.name
}

output "vnet_id" {
  description = "VNet ARM ID returned by the reusable network module."
  value       = module.network.id
}

output "vnet_name" {
  description = "Created VNet name."
  value       = module.network.name
}

output "vnet_address_space" {
  description = "Configured network address space, as returned by AzureRM."
  value       = module.network.address_space
}

output "subnet_ids" {
  description = "Subnet IDs keyed by name; workload is created by Vnet's nested subnet module."
  value       = module.network.subnet_ids
}

output "network_security_group_id" {
  description = "NSG attached to the workload subnet."
  value       = module.workload_nsg.id
}