output "id" {
  description = "Virtual machine resource ID."
  value       = azurerm_linux_virtual_machine.this.id
}

output "name" {
  description = "Virtual machine name."
  value       = azurerm_linux_virtual_machine.this.name
}

output "private_ip_address" {
  description = "Private IP of the NIC."
  value       = azurerm_network_interface.this.private_ip_address
}

output "network_interface_id" {
  description = "NIC resource ID."
  value       = azurerm_network_interface.this.id
}
