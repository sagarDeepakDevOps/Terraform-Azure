output "id" {
  description = "Firewall resource ID."
  value       = azurerm_firewall.this.id
}

output "name" {
  description = "Firewall name."
  value       = azurerm_firewall.this.name
}

output "private_ip_address" {
  description = "Next hop for spoke routes. Only available once the firewall and its rules exist."
  value       = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

output "public_ip_address" {
  description = "Egress and DNAT address."
  value       = azurerm_public_ip.data.ip_address
}

output "policy_id" {
  description = "Firewall policy resource ID."
  value       = azurerm_firewall_policy.this.id
}
