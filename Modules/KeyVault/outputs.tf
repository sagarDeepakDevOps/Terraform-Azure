output "id" {
  description = "Vault resource ID for RBAC and private endpoints."
  value       = azurerm_key_vault.this.id
}

output "uri" {
  description = "Vault URI; access requires a private network path and an appropriate Key Vault data role."
  value       = azurerm_key_vault.this.vault_uri
}