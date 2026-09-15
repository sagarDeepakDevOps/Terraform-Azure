# Purpose: Supply one AzureRM client for all VM, networking and backup child modules.
# Authentication: Real operations use external CLI/federated credentials and an
# explicit ARM_SUBSCRIPTION_ID; provider initialization alone provisions no VM.
# Important: Register the selected Compute/Network/Monitoring/Backup namespaces
# beforehand. Registration is deliberately not performed automatically by this client.
# Mocked Terraform tests replace the provider and do not incur cloud deployment costs.
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}