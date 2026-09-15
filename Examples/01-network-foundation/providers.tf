# Purpose: Configure the Azure API client inherited by this lab's child modules.
# Authentication: Use an approved Azure CLI login or federated identity and supply
# ARM_SUBSCRIPTION_ID for a real plan/apply; no credential is embedded in this file.
# features selects provider behavior, not resource creation. Registration is none
# so required Azure namespaces must already be registered by an authorized operator.
# Tests use mock_provider instead of this real client and do not create Azure resources.
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}