output "resource_group_name" {
  description = "Resource group holding everything."
  value       = module.resource_group.name
}

output "firewall_public_ip" {
  description = "Every spoke's Internet egress address, and the entry point for published VMs."
  value       = module.hub.firewall_public_ip
}

output "firewall_private_ip" {
  description = "Next hop of every spoke's default route."
  value       = module.hub.firewall_private_ip
}

output "published_urls" {
  description = "Open these in a browser. Traffic goes Internet, firewall DNAT, VM."
  value = {
    for name, port in local.public_ports : name => "http://${module.hub.firewall_public_ip}${port == 80 ? "" : ":${port}"}"
  }
}

output "vm_private_ips" {
  description = "Private IPs keyed by hostname."
  value       = { for key, vm in module.vms : key => vm.private_ip_address }
}

output "ssh_private_key_path" {
  description = "The generated private key, accepted by every VM."
  value       = module.ssh_key.private_key_path
}

output "bastion_ssh_commands" {
  description = "SSH into any VM through Bastion from your terminal. Needs bastion_sku Standard."
  value = {
    for key, vm in module.vms : key => "az network bastion ssh --name ${module.hub.bastion_name} --resource-group ${module.resource_group.name} --target-resource-id ${vm.id} --auth-type ssh-key --username ${var.admin_username} --ssh-key ${module.ssh_key.private_key_path}"
  }
}
