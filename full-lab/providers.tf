# Sign in with az login and export ARM_SUBSCRIPTION_ID before running Terraform.
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}
