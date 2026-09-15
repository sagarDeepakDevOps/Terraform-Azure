output "id" {
  description = "Storage account resource ID."
  value       = azurerm_storage_account.this.id
}

output "name" {
  description = "Storage account name."
  value       = azurerm_storage_account.this.name
}

output "blob_endpoint" {
  description = "Blob endpoint; access still requires networking and data-plane authorization."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "dfs_endpoint" {
  description = "Data Lake Gen2 endpoint."
  value       = azurerm_storage_account.this.primary_dfs_endpoint
}

output "container_ids" {
  description = "Container ARM IDs keyed by name."
  value       = { for name, container in azurerm_storage_container.this : name => container.id }
}

output "security" {
  description = "Storage security settings, useful for plan review."
  value = {
    public_network_access_enabled = azurerm_storage_account.this.public_network_access_enabled
    shared_access_key_enabled     = azurerm_storage_account.this.shared_access_key_enabled
    min_tls_version               = azurerm_storage_account.this.min_tls_version
  }
}