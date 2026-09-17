output "id" {
  description = "Load balancer resource ID."
  value       = azurerm_lb.this.id
}

output "backend_pool_id" {
  description = "Backend pool ID."
  value       = azurerm_lb_backend_address_pool.this.id
}

output "public_ip_address" {
  description = "Load balancer public IPv4 address."
  value       = azurerm_public_ip.this.ip_address
}

output "public_ip_fqdn" {
  description = "Frontend DNS name, or null when no domain_name_label was set."
  value       = azurerm_public_ip.this.fqdn
}
