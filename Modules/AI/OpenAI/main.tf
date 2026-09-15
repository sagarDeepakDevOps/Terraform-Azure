terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create the private Azure OpenAI account that owns inference deployments.
# Creation: AzureRM provisions kind OpenAI at S0 with the requested name/subdomain
# and a system-assigned identity. Model resources below reference this account ID.
# Security: Local API keys and public networking are disabled; callers create the
# private endpoint/DNS and grant authorized client identities OpenAI data access.
# Important: An account alone has no usable model deployment. Confirm subscription
# eligibility, region and quota, and do not confuse its system identity with a client.
resource "azurerm_cognitive_account" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  kind                          = "OpenAI"
  sku_name                      = "S0"
  custom_subdomain_name         = var.name
  public_network_access_enabled = false
  local_auth_enabled            = false
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# Purpose: Deploy only the explicitly selected OpenAI models for application inference.
# Creation: for_each creates one deployment per map key after the account exists.
# The key is the application's deployment name; model_name/model_version identify
# the underlying model, while sku_name/capacity choose its deployment allocation.
# Lifecycle: NoAutoUpgrade avoids requesting automatic version changes here, but
# does not override Azure model retirement or remove the need to plan upgrades.
# Important: Check current model/SKU availability, quota, processing/data-residency
# behavior and costs. Capacity units depend on the chosen model/deployment type;
# this block does not train a model, build an AI app or create Search indexes.
resource "azurerm_cognitive_deployment" "this" {
  for_each               = var.deployments
  name                   = each.key
  cognitive_account_id   = azurerm_cognitive_account.this.id
  version_upgrade_option = "NoAutoUpgrade"

  model {
    format  = "OpenAI"
    name    = each.value.model_name
    version = each.value.model_version
  }

  sku {
    name     = each.value.sku_name
    capacity = each.value.capacity
  }
}