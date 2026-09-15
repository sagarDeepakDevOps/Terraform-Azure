output "id" {
  description = "Automation account ID."
  value       = azurerm_automation_account.this.id
}

output "runbook_name" {
  description = "Runnable PowerShell example, with no external modules or credentials required."
  value       = azurerm_automation_runbook.this.name
}