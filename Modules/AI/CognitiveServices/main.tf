terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create an Azure AI multi-service account for supported cognitive APIs.
# Creation: AzureRM provisions kind CognitiveServices at S0 with a custom subdomain
# and system-assigned identity. Callers use its account ID for private endpoints
# and role grants, and its endpoint for correctly authenticated application calls.
# Security: Public networking and local API keys are disabled. A client needs an
# appropriate Entra data role plus private DNS/routing; creating the account identity
# does not automatically authorize that client.
# Important: Capability availability, eligibility and prices vary by service/region.
# This creates an account, not application code, a trained model or a complete AI solution.
resource "azurerm_cognitive_account" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  kind                          = "CognitiveServices"
  sku_name                      = "S0"
  custom_subdomain_name         = var.name
  public_network_access_enabled = false
  local_auth_enabled            = false
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }
}