output "resource_group_name" {
  description = "Resource group holding everything this configuration built."
  value       = module.resource_group.name
}

output "location" {
  description = "Region everything was created in."
  value       = module.resource_group.location
}

output "vnet_ids" {
  description = "VNet ARM IDs keyed by short name."
  value       = { for key, vnet in module.vnets : key => vnet.id }
}

output "subnet_ids" {
  description = "Subnet IDs keyed by VNet short name, then subnet name."
  value       = { for key, subnets in module.subnets : key => subnets.ids }
}

output "nsg_ids" {
  description = "NSG resource IDs keyed by the nsgs map key."
  value       = { for key, nsg in module.nsgs : key => nsg.id }
}

output "peering_ids" {
  description = "Both directional peering IDs for each configured peering."
  value       = { for key, peering in module.peerings : key => peering.ids }
}

output "nat_gateway_public_ips" {
  description = "Address the routed subnets appear to come from when reaching the Internet."
  value       = { for key, nat in module.nat_gateways : key => nat.public_ip_address }
}

output "vm_private_ips" {
  description = "Private addresses keyed by VM name; ping these from the jump host."
  value       = module.vms.private_ip_addresses
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

output "load_balancer_public_ip" {
  description = "Frontend IPv4 address. The web VMs already know it, so there is nothing to feed back in."
  value       = azurerm_public_ip.lb.ip_address
}

output "load_balancer_url" {
  description = "Open this in a browser. It is the only way in, because the web VMs have no public IP."
  value       = "http://${coalesce(module.load_balancer.public_ip_fqdn, module.load_balancer.public_ip_address)}"
}
