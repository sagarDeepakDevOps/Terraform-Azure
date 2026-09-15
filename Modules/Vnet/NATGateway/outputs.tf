output "id" {
  description = "NAT gateway resource ID."
  value       = azurerm_nat_gateway.this.id
}

output "public_ip_address" {
  description = "Deterministic outbound IPv4 address after deployment."
  value       = azurerm_public_ip.this.ip_address
}