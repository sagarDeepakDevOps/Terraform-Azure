# Purpose: Configure the AzureRM client for observability and governance resources.
# Authentication: Use the approved external identity plus ARM_SUBSCRIPTION_ID;
# that identity needs the selected policy, lock, billing and security permissions.
# Important: Required namespaces must be pre-registered. Optional Defender settings
# use this provider's entire subscription, not merely the example resource group.
# The tests substitute a mock provider and never change real subscription security.
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}