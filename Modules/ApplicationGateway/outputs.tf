output "id" {
  description = "Application Gateway resource ID."
  value       = azurerm_application_gateway.this.id
}

output "public_ip_address" {
  description = "Gateway listener public IP. Use the certificate hostname in clients."
  value       = azurerm_public_ip.this.ip_address
}