# Sign in with az login and export ARM_SUBSCRIPTION_ID before running Terraform.
# The backend reads that same variable to find the storage account.
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}
