# Purpose: Configure the AzureRM client inherited by Container Apps, ACR and optional AKS.
# Authentication: Real deployments use an approved external identity and
# ARM_SUBSCRIPTION_ID. That identity needs resource and scoped role-assignment rights.
# Important: Pre-register the selected container/network/monitoring namespaces;
# resource_provider_registrations=none avoids implicit subscription-wide registration.
# Tests replace this provider with a mock and never create a real cluster or container app.
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}