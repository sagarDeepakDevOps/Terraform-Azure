# Purpose: Configure the AzureRM API client inherited by the starter's child modules.
# Authentication: For a live plan/apply, use an approved Azure CLI login or federated
# identity and set ARM_SUBSCRIPTION_ID. Never put credentials into module source code.
# Creation: This block configures a client, not a resource. The module calls in
# main.tf determine which Azure resources a reviewed terraform apply will create.
# Important: Automatic resource-provider registration is disabled. An authorized
# subscription administrator must register Microsoft.Network before live deployment.
# The root tests replace this client with mock_provider and create no Azure resources.
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}