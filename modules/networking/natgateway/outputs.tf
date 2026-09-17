output "id" {
  description = "NAT gateway resource ID."
  value       = azurerm_nat_gateway.this.id
}

output "public_ip_address" {
  description = "Address the routed subnets use for outbound traffic."
  value       = azurerm_public_ip.this.ip_address
}
