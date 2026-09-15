# Purpose: Configure the AzureRM client that creates the shared backend infrastructure.
# Authentication: Use an approved external identity and ARM_SUBSCRIPTION_ID, with
# resource creation, scoped role-grant and lock permissions. Register Storage beforehand.
# Storage: Skip data-plane provisioning probes while the account/firewall/roles are
# established and use Entra where supported, without enabling shared account keys.
# Important: This configures the resource provider, not Terraform's state backend.
# Once a workload adopts Blob state, backend access still requires its own Entra
# data role and permitted network path; this feature does not bypass either check.
provider "azurerm" {
  features {
    storage {
      data_plane_available = false
    }
  }
  resource_provider_registrations = "none"
  storage_use_azuread             = true
}

# Purpose: Provide the generic ARM client required by the reusable Storage module.
# Evaluation: The module declares it for optional Table resources, but this bootstrap
# creates only the tfstate Blob container. Provider configuration alone makes no
# Table or state write and obtains any required credentials externally.
provider "azapi" {}