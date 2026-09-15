output "id" {
  description = "Windows VM resource ID."
  value       = azurerm_windows_virtual_machine.this.id
}

output "private_ip_address" {
  description = "Private Windows VM address."
  value       = azurerm_network_interface.this.private_ip_address
}