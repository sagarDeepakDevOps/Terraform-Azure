# Generated once and kept in state, so the account name never changes on later applies.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# The identity running Terraform; only used to grant it blob access.
data "azurerm_client_config" "current" {}

# Holds every other configuration's state, so it lives in its own resource group.
resource "azurerm_storage_account" "this" {
  name                            = local.account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = var.replication_type
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = var.shared_access_key_enabled
  tags                            = var.tags

  # Versioning keeps every earlier copy of a state blob; soft delete covers a deleted blob or container.
  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = var.retention_days
    }

    container_delete_retention_policy {
      days = var.retention_days
    }
  }

  # Only when addresses are listed; a firewall that misses your IP turns every plan into a 403.
  dynamic "network_rules" {
    for_each = length(var.allowed_ip_ranges) > 0 ? [1] : []
    content {
      default_action = "Deny"
      ip_rules       = var.allowed_ip_ranges
      bypass         = ["AzureServices"]
    }
  }
}

# One blob per configuration; the backend locks by leasing that blob, so no lock table is needed.
resource "azurerm_storage_container" "this" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

# Owner has no data-plane rights, so use_azuread_auth needs this role or init returns 403.
resource "azurerm_role_assignment" "current_user" {
  count = var.grant_current_user_blob_access ? 1 : 0

  scope                = local.container_scope
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Off by default, because it also blocks terraform destroy of this configuration.
resource "azurerm_management_lock" "this" {
  count = var.enable_delete_lock ? 1 : 0

  name       = "${local.account_name}-no-delete"
  scope      = azurerm_storage_account.this.id
  lock_level = "CanNotDelete"
  notes      = "Holds Terraform state. Remove this lock before deleting the account."
}
