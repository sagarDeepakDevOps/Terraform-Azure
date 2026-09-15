output "id" {
  description = "Bastion resource ID. Target VM NSGs must separately allow SSH/RDP from AzureBastionSubnet."
  value       = azurerm_bastion_host.this.id
}