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
  description = "Private addresses keyed by VM name; ping these from the jump host across the peering."
  value       = module.vms.private_ip_addresses
}

output "vm_urls" {
  description = "Direct URLs for VMs that have a public IP. Private backends are absent here by design; reach them through load_balancer_url or from the jump host."
  value = {
    for name, vm in var.vms : name => "http://${coalesce(module.vms.public_ip_fqdns[name], module.vms.public_ip_addresses[name])}"
    if vm.role == "web" && vm.public_ip_enabled
  }
}

output "load_balancer_public_ip" {
  description = "Load balancer frontend IPv4 address."
  value       = module.load_balancer.public_ip_address
}

output "load_balancer_url" {
  description = "Load balancer entry point; reports the frontend address instead of a VM's."
  value       = "http://${coalesce(module.load_balancer.public_ip_fqdn, module.load_balancer.public_ip_address)}"
}

output "ssh_private_key_path" {
  description = "The single generated private key, accepted by every VM in the lab."
  value       = module.vms.private_key_path
}

output "ssh_commands" {
  description = "SSH commands for VMs reachable from outside. Private VMs are absent; hop to them from a jump host with the same key, which the module already installed everywhere."
  value = {
    for name, vm in var.vms : name => "ssh -i ${module.vms.private_key_path} ${var.admin_username}@${module.vms.public_ip_addresses[name]}"
    if vm.public_ip_enabled
  }
}

output "private_ssh_commands" {
  description = "How to reach every VM by private address once you are on a jump host."
  value = {
    for name, ip in module.vms.private_ip_addresses :
    name => "ssh -i ~/${basename(module.vms.private_key_path)} ${var.admin_username}@${ip}"
  }
}
