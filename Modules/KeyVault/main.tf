terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Provision a private vault for workload secrets, keys and certificates.
# Creation: AzureRM creates the globally named Standard vault in the supplied Entra
# tenant and resource group, using Azure RBAC rather than inline access policies.
# Callers separately grant the appropriate Key Vault data roles and create a vault
# private endpoint with its DNS zone; this block does not seed any secret values.
# Security: Public access is disabled and network ACLs default to Deny. The limited
# AzureServices bypass is not authorization for all Azure clients or all identities.
# Recovery: Soft deletion retains deleted data for seven days and purge protection
# blocks early permanent deletion. Reusing a deleted vault name may therefore wait.
# Important: Resource management permission alone does not allow secret reads;
# clients need both data authorization and the intended private network/DNS path.
resource "azurerm_key_vault" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7
  public_network_access_enabled = false
  tags                          = var.tags

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}