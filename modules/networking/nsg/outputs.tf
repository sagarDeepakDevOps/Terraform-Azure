output "id" {
  description = "Network security group resource ID."
  value       = azurerm_network_security_group.this.id
}

output "name" {
  description = "Network security group name."
  value       = azurerm_network_security_group.this.name
}
