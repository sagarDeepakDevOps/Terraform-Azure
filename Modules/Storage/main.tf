# Purpose: Declare the Terraform/provider versions this reusable module needs.
# Creation: terraform init resolves compatible AzureRM and AzAPI packages together
# with the root constraints; the root lock file records exact selected versions.
# AzureRM manages the storage account and most children; AzAPI creates Tables via
# ARM. Credentials/provider configurations come from the caller, not this module.
terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.0.0, < 3.0.0"
    }
  }
}

# Purpose: Create a general-purpose StorageV2 account for blobs, files and messages,
# or enable the hierarchical namespace when the caller needs an ADLS Gen2 lake.
# Creation: AzureRM sends the configured name, region, resource group, Standard
# tier and replication choice to Azure Resource Manager. The group must exist;
# passing a resource-group module output gives Terraform that dependency.
# Security: Require HTTPS/TLS 1.2, block anonymous blobs and shared account keys,
# disable cross-tenant replication, and deny network traffic except configured
# exceptions. AzureServices bypass covers supported trusted services, not all Azure
# clients, and does not itself grant data authorization or override disabled public
# access. Public access is controlled separately by the caller's boolean.
# Recovery: Keep deleted blobs/containers for seven days; enable blob versioning
# only without HNS because ADLS Gen2 does not support that versioning combination.
# Important: Private-account callers set features.storage.data_plane_available to
# false in the root provider so creation does not wait for not-yet-created private
# endpoints. Real data use still needs reachable networking, DNS and Entra roles.
resource "azurerm_storage_account" "this" {
  name                             = var.name
  resource_group_name              = var.resource_group_name
  location                         = var.location
  account_kind                     = "StorageV2"
  account_tier                     = "Standard"
  account_replication_type         = var.replication_type
  min_tls_version                  = "TLS1_2"
  https_traffic_only_enabled       = true
  allow_nested_items_to_be_public  = false
  shared_access_key_enabled        = false
  default_to_oauth_authentication  = true
  public_network_access_enabled    = var.public_network_access_enabled
  is_hns_enabled                   = var.hierarchical_namespace_enabled
  cross_tenant_replication_enabled = false
  tags                             = var.tags

  blob_properties {
    versioning_enabled = !var.hierarchical_namespace_enabled
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = var.allowed_ip_addresses
  }
}

# Purpose: Create the caller's named, non-anonymous blob containers.
# Creation: for_each makes one container per entry in var.containers. Referencing
# the new account's ARM ID orders creation and selects the management-plane API;
# Terraform need not upload a blob or obtain a shared key to create the container.
# With HNS enabled, these containers also serve as ADLS Gen2 filesystem roots.
# Important: This creates empty containers, not folders/files or data permissions.
resource "azurerm_storage_container" "this" {
  for_each              = var.containers
  name                  = each.value
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

# Purpose: Provision SMB Azure Files shares for shared file storage.
# Creation: Each file_shares map key becomes a share name and its numeric value
# becomes the quota in GiB. The account ID creates an implicit dependency and uses
# the ARM form of the share resource rather than requiring data-plane credentials.
# Important: This does not configure SMB domain/identity integration, mount a drive
# or set directory permissions. Configure an appropriate identity model before use;
# the parent account deliberately keeps shared-key authentication disabled.
resource "azurerm_storage_share" "this" {
  for_each           = var.file_shares
  name               = each.key
  storage_account_id = azurerm_storage_account.this.id
  quota              = each.value
  enabled_protocol   = "SMB"
}

# Purpose: Provision simple Storage Queues for asynchronous application messages.
# Creation: Create one empty queue for each configured name after the account
# exists. storage_account_id selects AzureRM's Resource Manager creation path.
# Important: Applications still need Queue data roles and network access. This
# block does not send messages, create consumers, or configure Service Bus features.
resource "azurerm_storage_queue" "this" {
  for_each           = var.queues
  name               = each.value
  storage_account_id = azurerm_storage_account.this.id
}

# Purpose: Provision Azure Storage Tables without enabling shared account keys.
# Creation: AzAPI sends one ARM request per table name using the explicit Storage
# API version. parent_id identifies the new account's built-in default table service;
# Azure creates the empty table beneath it using the supplied properties object.
# Why AzAPI: The AzureRM Table resource still uses shared-key data-plane operations
# for its ACL handling. This ARM route fits the account's key-disabled design.
# Important: Table names must satisfy Azure's naming rules; entities, application
# data access and any table-level application schema are outside this resource.
resource "azapi_resource" "table" {
  for_each  = var.tables
  type      = "Microsoft.Storage/storageAccounts/tableServices/tables@2023-05-01"
  name      = each.value
  parent_id = "${azurerm_storage_account.this.id}/tableServices/default"
  body      = { properties = {} }
}

# Purpose: Demonstrate automatic blob tiering and eventual data deletion.
# Creation: count creates one account-level management policy only when explicitly
# enabled. The policy targets block blobs under the data/ prefix: move their base
# blobs to Cool after 30 days, Archive after 90 days, and delete after 365 days
# since modification. The account ID orders this policy after account creation.
# Important: These are storage-service lifecycle actions, not actions performed
# immediately by Terraform. Archive retrieval has latency and costs; confirm SKU
# support and retention requirements. This rule does not clean up old blob versions
# and must be reviewed before putting real or regulated data in the matching path.
resource "azurerm_storage_management_policy" "this" {
  count              = var.enable_lifecycle_policy ? 1 : 0
  storage_account_id = azurerm_storage_account.this.id

  rule {
    name    = "archive-data"
    enabled = true
    filters {
      prefix_match = ["data/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
        delete_after_days_since_modification_greater_than          = 365
      }
    }
  }
}