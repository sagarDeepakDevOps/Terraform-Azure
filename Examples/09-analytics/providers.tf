# Purpose: Configure AzureRM for the lake and optional private analytics platforms.
# Authentication: Use external credentials and ARM_SUBSCRIPTION_ID; pre-register
# only the namespaces needed for the chosen platforms.
# Storage: Skip data-plane availability checks during ARM-based private lake creation
# and prefer Entra authentication for supported storage operations.
# Important: This storage feature does not bypass Synapse's private Dev data-plane
# API; configure managed Synapse endpoints later from a connected authorized runner.
provider "azurerm" {
  features {
    storage {
      data_plane_available = false
    }
  }
  resource_provider_registrations = "none"
  storage_use_azuread             = true
}

# Purpose: Supply the generic ARM provider required by the shared Storage module.
# Evaluation: Its optional Table branch is unused for this ADLS filesystem example;
# the declaration creates no object and obtains any needed credentials externally.
provider "azapi" {}