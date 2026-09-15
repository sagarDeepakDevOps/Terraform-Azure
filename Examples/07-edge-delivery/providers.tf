# Purpose: Supply the AzureRM client used by Front Door, WAF, DNS and regional hosting.
# Authentication: Use external CLI/federated credentials plus ARM_SUBSCRIPTION_ID
# for real operations. Child modules inherit this configuration without their own secrets.
# Important: Pre-register the required Network/Web/CDN namespaces; automatic
# registration is disabled. Tests use a mock provider, not billable edge deployments.
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}