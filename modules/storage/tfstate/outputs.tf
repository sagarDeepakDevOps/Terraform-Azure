output "storage_account_name" {
  description = "Storage account holding the state container."
  value       = azurerm_storage_account.this.name
}

output "storage_account_id" {
  description = "Storage account resource ID."
  value       = azurerm_storage_account.this.id
}

output "container_name" {
  description = "Blob container each configuration writes its state blob into."
  value       = azurerm_storage_container.this.name
}

output "resource_group_name" {
  description = "Resource group the account lives in; the backend block needs it."
  value       = var.resource_group_name
}

output "use_azuread_auth" {
  description = "Whether the backend should authenticate as the signed-in identity instead of with an account key."
  value       = var.grant_current_user_blob_access
}

output "backend_hcl" {
  description = "Partial backend configuration. Each root supplies its own key and passes this file to terraform init -backend-config."
  value       = <<-EOT
    resource_group_name  = "${var.resource_group_name}"
    storage_account_name = "${azurerm_storage_account.this.name}"
    container_name       = "${azurerm_storage_container.this.name}"
    use_azuread_auth     = ${var.grant_current_user_blob_access}
  EOT
}
