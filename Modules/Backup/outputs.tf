output "id" {
  description = "Recovery Services vault ID."
  value       = azurerm_recovery_services_vault.this.id
}

output "policy_id" {
  description = "Daily VM backup policy ID."
  value       = azurerm_backup_policy_vm.this.id
}