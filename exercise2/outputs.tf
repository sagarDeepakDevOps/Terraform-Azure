output "vnet_names" {
  description = "VNet names keyed by short name; exercise3 and exercise5 look them up by these names."
  value       = { for key, vnet in module.vnets : key => vnet.name }
}

output "vnet_ids" {
  description = "VNet ARM IDs keyed by short name."
  value       = { for key, vnet in module.vnets : key => vnet.id }
}
