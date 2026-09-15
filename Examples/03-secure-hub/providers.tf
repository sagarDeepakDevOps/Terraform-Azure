# Purpose: Configure the inherited AzureRM client for hub, firewall and gateway resources.
# Authentication: Select the approved subscription through ARM_SUBSCRIPTION_ID and
# external CLI/federated authentication; sensitive VPN inputs are not provider credentials.
# Important: Required resource namespaces must be pre-registered. The provider does
# not create paid appliances merely by being configured; actual apply performs those changes.
# The mock_provider used in tests bypasses real Azure provisioning entirely.
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}