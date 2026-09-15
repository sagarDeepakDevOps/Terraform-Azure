output "id" {
  description = "Virtual machine resource ID."
  value       = azurerm_linux_virtual_machine.this.id
}

output "network_interface_id" {
  description = "NIC ID for load balancer pool association."
  value       = azurerm_network_interface.this.id
}

output "private_ip_address" {
  description = "Private VM address."
  value       = azurerm_network_interface.this.private_ip_address
}

output "principal_id" {
  description = "System-assigned managed identity principal ID."
  value       = azurerm_linux_virtual_machine.this.identity[0].principal_id
}