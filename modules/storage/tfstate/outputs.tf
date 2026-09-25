output "storage_account_name" {
  description = "Account name, needed by every backend block."
  value       = azurerm_storage_account.this.name
}

output "storage_account_id" {
  description = "Account resource ID."
  value       = azurerm_storage_account.this.id
}

output "container_name" {
  description = "Container the state blobs go into."
  value       = azurerm_storage_container.this.name
}

output "use_azuread_auth" {
  description = "Whether backends should sign in with Entra ID instead of the account key."
  value       = var.grant_current_user_blob_access
}

output "backend_hcl" {
  description = "Partial backend configuration for terraform init -backend-config. Names only, no keys."
  value       = local.backend_hcl
}
