output "ids" {
  description = "Virtual machine resource IDs keyed by VM name."
  value       = { for key, vm in azurerm_linux_virtual_machine.this : key => vm.id }
}

output "network_interface_ids" {
  description = "NIC IDs keyed by VM name, for load balancer backend pool association."
  value       = { for key, nic in azurerm_network_interface.this : key => nic.id }
}

output "private_ip_addresses" {
  description = "Private VM addresses keyed by VM name."
  value       = { for key, nic in azurerm_network_interface.this : key => nic.private_ip_address }
}

output "public_ip_addresses" {
  description = "Instance-level public IPv4 addresses keyed by VM name; null for VMs without one."
  value       = { for key in keys(var.vms) : key => try(azurerm_public_ip.this[key].ip_address, null) }
}

output "public_ip_fqdns" {
  description = "Public IP DNS names keyed by VM name; null where no domain_name_label was set."
  value       = { for key in keys(var.vms) : key => try(azurerm_public_ip.this[key].fqdn, null) }
}

output "principal_ids" {
  description = "System-assigned managed identity principal IDs keyed by VM name."
  value       = { for key, vm in azurerm_linux_virtual_machine.this : key => vm.identity[0].principal_id }
}

output "private_key_path" {
  description = "The single generated private key file, accepted by every VM this module builds."
  value       = local_sensitive_file.private_key.filename
}
