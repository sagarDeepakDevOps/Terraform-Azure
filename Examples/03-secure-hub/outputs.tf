output "firewall_private_ip" {
  description = "Next hop for the spoke default route."
  value       = module.firewall.private_ip_address
}

output "hub_subnets" {
  description = "Azure-reserved hub subnet IDs."
  value       = module.hub.subnet_ids
}

output "optional_components" {
  description = "Optional paid hub components."
  value       = { bastion = var.enable_bastion, vpn = var.enable_vpn }
}

output "vpn_public_ip" {
  description = "Public peer IP, only available when VPN is enabled."
  value       = var.enable_vpn ? module.vpn[0].public_ip_address : null
}