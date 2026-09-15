output "resource_group_name" {
  description = "Resource group created by this lab."
  value       = module.resource_group.name
}

output "hub_address_space" {
  description = "Hub VNet address space."
  value       = module.hub.address_space
}

output "hub_subnet_ids" {
  description = "Hub subnet IDs."
  value       = module.hub.subnet_ids
}

output "peering_ids" {
  description = "Both sides of the hub-spoke peering."
  value       = module.peering.ids
}

output "spoke_subnet_ids" {
  description = "Spoke subnet IDs."
  value       = module.spoke.subnet_ids
}