terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Provision Azure Managed Redis for low-latency, rebuildable application cache.
# Creation: Azure creates the requested SKU and default database together, enabling
# encrypted client connections, OSSCluster-aware routing and AllKeysLRU eviction.
# The caller creates a redisEnterprise private endpoint and matching DNS because
# public_network_access is Disabled. Use the reported database port, not an assumed
# legacy Redis port, and configure a client that supports the clustering policy.
# Security: Access-key authentication is enabled for this demo; those keys remain
# sensitive in Terraform state. Prefer an appropriate Entra access model in production.
# Important: HA is explicitly disabled and persistence is not configured. Cached
# data can be lost, some database setting changes recreate data, and idle capacity
# is still billable. This is not the legacy Azure Cache for Redis resource.
resource "azurerm_managed_redis" "this" {
  name                      = var.name
  resource_group_name       = var.resource_group_name
  location                  = var.location
  sku_name                  = var.sku_name
  high_availability_enabled = false
  public_network_access     = "Disabled"
  tags                      = var.tags

  default_database {
    access_keys_authentication_enabled = true
    client_protocol                    = "Encrypted"
    clustering_policy                  = "OSSCluster"
    eviction_policy                    = "AllKeysLRU"
  }
}