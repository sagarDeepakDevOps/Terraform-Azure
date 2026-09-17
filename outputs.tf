output "resource_group_name" {
  description = "Resource group that owns the lab; deleting it removes everything."
  value       = module.resource_group.name
}

output "vnet_ids" {
  description = "Virtual network ARM IDs keyed by the var.vnets key."
  value       = { for name, vnet in module.vnets : name => vnet.id }
}

output "subnet_ids" {
  description = "Subnet IDs keyed by network name, then by subnet name."
  value       = { for name, vnet in module.vnets : name => vnet.subnet_ids }
}

output "peering_ids" {
  description = "Both directional peering IDs for each configured peering."
  value       = { for name, peering in module.peerings : name => peering.ids }
}

output "vm_private_ips" {
  description = "Backend private addresses, shown on both demo pages."
  value       = { for name, vm in module.vms : name => vm.private_ip_address }
}

output "vm_urls" {
  description = "Direct per-VM URLs; each reports that VM's own public IP."
  value       = { for name, vm in module.vms : name => "http://${coalesce(vm.public_ip_fqdn, vm.public_ip_address)}" }
}

output "load_balancer_public_ip" {
  description = "Load balancer frontend IPv4 address."
  value       = module.load_balancer.public_ip_address
}

output "load_balancer_url" {
  description = "Load balancer entry point; reports the frontend address instead of a VM's."
  value       = "http://${coalesce(module.load_balancer.public_ip_fqdn, module.load_balancer.public_ip_address)}"
}

output "ssh_private_key_paths" {
  description = "Generated private key file per VM. Connect with: ssh -i <path> azureuser@<vm public ip>"
  value       = { for name, vm in module.vms : name => vm.private_key_path }
}
