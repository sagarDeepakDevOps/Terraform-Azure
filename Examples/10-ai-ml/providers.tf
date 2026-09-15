# Purpose: Configure the inherited AzureRM client for AI accounts and optional ML dependencies.
# Authentication: Use external CLI/federated credentials plus ARM_SUBSCRIPTION_ID;
# service namespaces must be registered and the caller needs the selected role-grant rights.
# Storage: Skip private storage data-plane bootstrap probes and prefer Entra auth for
# supported operations. These options do not create the application's network/data access.
# Recovery: Do not automatically purge soft-deleted Cognitive Services accounts or
# Key Vaults on destroy; retained names/data can affect later cleanup and name reuse.
# Important: Tests replace AzureRM with a mock, so passing tests does not confirm
# live model quota, regional availability, private reachability or actual model inference.
provider "azurerm" {
  features {
    storage {
      data_plane_available = false
    }
    cognitive_account {
      purge_soft_delete_on_destroy = false
    }
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
  resource_provider_registrations = "none"
  storage_use_azuread             = true
}

# Purpose: Supply the generic ARM provider declared by the shared Storage module.
# Evaluation: It authenticates from the same external Azure context; the optional
# Table-creation branch is not selected by this ML storage example. No resource is
# created simply by declaring this provider.
provider "azapi" {}