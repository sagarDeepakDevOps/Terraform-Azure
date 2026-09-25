locals {
  # Account names are global, 3-24 lowercase letters or digits, so hyphens go and a random tail is added.
  prefix_chars   = replace(lower(var.name_prefix), "/[^a-z0-9]/", "")
  generated_name = "${substr(local.prefix_chars, 0, min(18, length(local.prefix_chars)))}${random_string.suffix.result}"
  account_name   = coalesce(var.storage_account_name, local.generated_name)

  # Smallest scope the backend needs, so the role assignment grants nothing beyond this container.
  container_scope = "${azurerm_storage_account.this.id}/blobServices/default/containers/${azurerm_storage_container.this.name}"

  backend_hcl = <<-EOT
    resource_group_name  = "${var.resource_group_name}"
    storage_account_name = "${azurerm_storage_account.this.name}"
    container_name       = "${azurerm_storage_container.this.name}"
    use_azuread_auth     = ${var.grant_current_user_blob_access}
  EOT
}
