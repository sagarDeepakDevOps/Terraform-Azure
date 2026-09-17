output "id" {
  description = "Virtual machine resource ID."
  value       = azurerm_linux_virtual_machine.this.id
}

output "network_interface_id" {
  description = "NIC ID for load balancer backend pool association."
  value       = azurerm_network_interface.this.id
}

output "private_ip_address" {
  description = "Private VM address."
  value       = azurerm_network_interface.this.private_ip_address
}

output "public_ip_address" {
  description = "Instance-level public IPv4 address, or null when public_ip_enabled is false."
  value       = var.public_ip_enabled ? azurerm_public_ip.this[0].ip_address : null
}

output "public_ip_fqdn" {
  description = "Public IP DNS name, or null when no domain_name_label was set."
  value       = var.public_ip_enabled ? azurerm_public_ip.this[0].fqdn : null
}

output "private_key_path" {
  description = "Generated private key file for this VM. Connect with: ssh -i <path> <admin_username>@<public ip>"
  value       = local_sensitive_file.private_key.filename
}

output "principal_id" {
  description = "System-assigned managed identity principal ID."
  value       = azurerm_linux_virtual_machine.this.identity[0].principal_id
}
