# Authenticate with an approved Azure CLI login or federated identity and set ARM_SUBSCRIPTION_ID; never hardcode credentials.
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}
