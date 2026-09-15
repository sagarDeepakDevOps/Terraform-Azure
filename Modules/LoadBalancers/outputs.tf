output "id" {
  description = "Load balancer resource ID."
  value       = azurerm_lb.this.id
}

output "backend_pool_id" {
  description = "Backend pool ID for VM scale sets."
  value       = azurerm_lb_backend_address_pool.this.id
}

output "public_ip_address" {
  description = "Load balancer public IPv4 address."
  value       = azurerm_public_ip.this.ip_address
}