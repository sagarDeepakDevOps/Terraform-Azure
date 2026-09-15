output "id" {
  description = "Firewall resource ID."
  value       = azurerm_firewall.this.id
}

output "private_ip_address" {
  description = "Firewall private address for VirtualAppliance routes."
  value       = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

output "public_ip_address" {
  description = "Firewall outbound public address."
  value       = azurerm_public_ip.this.ip_address
}