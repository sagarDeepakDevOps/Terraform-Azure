# Purpose: Configure one AzureRM client for messaging, events and private source storage.
# Authentication: Use the approved external identity/subscription and pre-register
# the required service namespaces; no credentials or registration actions are hidden here.
# Storage: data_plane_available=false avoids private-account bootstrap probes;
# storage_use_azuread selects Entra for supported data operations rather than shared keys.
# Important: A real blob upload still needs a private path and data permission.
# Terraform mock tests replace this real client and do not send production events.
provider "azurerm" {
  features {
    storage {
      data_plane_available = false
    }
  }
  resource_provider_registrations = "none"
  storage_use_azuread             = true
}

# Purpose: Provide the ARM client declared by the reusable Storage module.
# Evaluation: Optional Table resources use it when requested; this root only requests
# Blob containers, so this provider declaration itself makes no Table or data write.
provider "azapi" {}