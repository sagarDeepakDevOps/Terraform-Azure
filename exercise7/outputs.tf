output "vm_private_ips" {
  description = "Private addresses keyed by VM name; ping these from the jump host."
  value       = module.vms.private_ip_addresses
}

output "network_interface_names" {
  description = "NIC names keyed by VM name. Exercise8 looks these up to build the backend pool."
  value       = { for name in keys(var.vms) : name => "${var.prefix}-${name}-nic" }
}

output "ssh_private_key_path" {
  description = "The single generated private key, accepted by every VM."
  value       = module.vms.private_key_path
}

output "ssh_commands" {
  description = "SSH commands for VMs reachable from outside. Private VMs are absent; hop to them from the jump host."
  value = {
    for name, vm in var.vms : name => "ssh -i ${module.vms.private_key_path} ${var.admin_username}@${module.vms.public_ip_addresses[name]}"
    if vm.public_ip_enabled
  }
}
