output "id" {
  description = "Network security group resource ID."
  value       = azurerm_network_security_group.this.id
}

output "association_ids" {
  description = "Subnet association IDs, required by Databricks VNet injection."
  value       = { for name, association in azurerm_subnet_network_security_group_association.this : name => association.id }
}