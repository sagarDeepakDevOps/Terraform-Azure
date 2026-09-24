# Names are global and 3-24 lowercase letters or digits, so strip hyphens and add a random suffix.
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

# Holds all other state, so never put it in a resource group you tear down.
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

  # When off, the backend authenticates as you instead of with a fetchable account key.
  shared_access_key_enabled = var.shared_access_key_enabled

  blob_properties {
    # Each apply overwrites one blob; versioning lets you restore state from before a bad apply.
    versioning_enabled = true

    delete_retention_policy {
      days = var.retention_days
    }

    container_delete_retention_policy {
      days = var.retention_days
    }
  }

  # Omitted by default: a firewall that misses your IP turns every plan into a 403.
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

# One container, one blob per configuration; the backend locks with a blob lease, so no lock table.
resource "azurerm_storage_container" "this" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

# Blob access needs a data-plane role that Owner lacks; without it use_azuread_auth gets a 403.
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
