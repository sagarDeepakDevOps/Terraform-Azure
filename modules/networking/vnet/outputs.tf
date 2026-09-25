output "id" {
  description = "Virtual network resource ID."
  value       = azurerm_virtual_network.this.id
}

output "name" {
  description = "Virtual network name."
  value       = azurerm_virtual_network.this.name
}

output "address_space" {
  description = "VNet CIDR ranges."
  value       = azurerm_virtual_network.this.address_space
}

output "subnet_ids" {
  description = "Subnet IDs keyed by subnet name."
  value       = { for key, subnet in module.subnets : key => subnet.id }
}
