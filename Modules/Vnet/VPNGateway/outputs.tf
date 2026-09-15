output "id" {
  description = "VPN gateway resource ID."
  value       = azurerm_virtual_network_gateway.this.id
}

output "public_ip_address" {
  description = "Azure gateway public IPv4 address for remote VPN configuration."
  value       = azurerm_public_ip.this.ip_address
}