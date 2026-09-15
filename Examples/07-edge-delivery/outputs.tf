output "front_door_url" {
  description = "Use the default Front Door HTTPS endpoint until custom-domain validation and certificates are configured."
  value       = "https://${module.front_door.hostname}"
}

output "waf_mode" {
  description = "Front Door WAF operating mode."
  value       = module.front_door.waf_mode
}

output "dns_name_servers" {
  description = "Public DNS nameservers; no registrar changes are made automatically."
  value       = module.dns.name_servers
}

output "application_gateway_ip" {
  description = "Optional gateway public IP; configure its certificate hostname in DNS."
  value       = var.enable_application_gateway ? module.application_gateway[0].public_ip_address : null
}

output "traffic_manager_fqdn" {
  description = "Optional DNS failover endpoint."
  value       = length(var.traffic_manager_endpoints) > 0 ? module.traffic_manager[0].fqdn : null
}