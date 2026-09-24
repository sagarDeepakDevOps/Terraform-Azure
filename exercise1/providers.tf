# Sign in with az login and export ARM_SUBSCRIPTION_ID before running Terraform.
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  resource_provider_registrations = "none"
}
