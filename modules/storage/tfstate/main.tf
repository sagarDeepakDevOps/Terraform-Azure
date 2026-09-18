# Storage account names are global across all of Azure and allow only 3-24
# lowercase letters and digits, so the lab prefix is stripped of its hyphens and
# given a random tail rather than used as-is.
resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  sanitized = replace(lower(var.name_prefix), "/[^a-z0-9]/", "")
  generated = "${substr(local.sanitized, 0, min(17, length(local.sanitized)))}${random_string.suffix.result}"

  account_name = coalesce(var.storage_account_name, local.generated)

  # A data-plane role, and the container is the smallest scope the backend needs.
  container_scope = "${azurerm_storage_account.this.id}/blobServices/default/containers/${var.container_name}"
}

# Whoever runs Terraform, used only to grant that identity access to the blobs.
data "azurerm_client_config" "current" {}

# Holds every other configuration's state, so it must outlive them: never put it
# in a resource group you tear down between sessions.
resource "azurerm_storage_account" "this" {
  name                = local.account_name
  resource_group_name = var.resource_group_name
  location            = var.location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = var.replication_type

  # State is read and written over the public endpoint from your machine.
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true

  # Off means the backend must authenticate as you, rather than with an account
  # key that anyone able to read the account can fetch.
  shared_access_key_enabled = var.shared_access_key_enabled

  blob_properties {
    # Every apply overwrites one blob. Versioning is what lets you go back to the
    # state as it was before an apply that went wrong.
    versioning_enabled = true

    delete_retention_policy {
      days = var.retention_days
    }

    container_delete_retention_policy {
      days = var.retention_days
    }
  }

  # Absent by default: a firewall that does not list your address turns every
  # plan into a 403, including the container creation below.
  dynamic "network_rules" {
    for_each = length(var.allowed_ip_ranges) > 0 ? [1] : []
    content {
      default_action = "Deny"
      ip_rules       = var.allowed_ip_ranges
      bypass         = ["AzureServices"]
    }
  }

  tags = var.tags
}

# One container holding one blob per configuration. The azurerm backend takes its
# lock as a lease on that blob, so there is no lock table to create.
resource "azurerm_storage_container" "this" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

# Reading and writing a blob is a data-plane operation, and subscription roles
# such as Owner do not grant it. Without this, use_azuread_auth gets a 403.
resource "azurerm_role_assignment" "current_user" {
  count = var.grant_current_user_blob_access ? 1 : 0

  scope                = local.container_scope
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id

  depends_on = [azurerm_storage_container.this]
}

# Optional, and off by default because it also blocks terraform destroy here.
resource "azurerm_management_lock" "this" {
  count = var.enable_delete_lock ? 1 : 0

  name       = "${local.account_name}-no-delete"
  scope      = azurerm_storage_account.this.id
  lock_level = "CanNotDelete"
  notes      = "Holds the Terraform state for this lab. Remove the lock before deleting."
}
