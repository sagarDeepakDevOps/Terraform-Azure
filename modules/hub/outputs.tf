output "vnet" {
  description = "Hub VNet name, ID and resource group, which is what a spoke needs to peer with it."
  value = {
    name                = module.vnet.name
    id                  = module.vnet.id
    resource_group_name = var.resource_group_name
  }
}

output "firewall_private_ip" {
  description = "Next hop for every spoke's default route."
  value       = module.firewall.private_ip_address
}

output "firewall_public_ip" {
  description = "Spoke egress address and entry point for published VMs."
  value       = module.firewall.public_ip_address
}

output "bastion_name" {
  description = "Bastion host name."
  value       = module.bastion.name
}
