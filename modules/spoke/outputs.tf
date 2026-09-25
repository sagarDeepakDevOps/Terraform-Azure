output "vnet_id" {
  description = "Spoke VNet resource ID."
  value       = module.vnet.id
}

output "vnet_name" {
  description = "Spoke VNet name."
  value       = module.vnet.name
}

# Released only once the NSG, route and peering are in place, so VMs never boot without a path out.
output "subnet_ids" {
  description = "Subnet IDs keyed by subnet name, available after the NSGs, route table and peering are attached."
  value       = module.vnet.subnet_ids

  depends_on = [module.nsgs, module.route_table, module.peering]
}
