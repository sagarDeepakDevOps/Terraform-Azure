# Purpose: Configure the AzureRM client for hosting and private Function storage.
# Authentication: Real operations use external CLI/federated credentials and
# ARM_SUBSCRIPTION_ID; required service namespaces must be pre-registered.
# Storage: Skip initial data-plane probes so account creation does not wait for
# dependent private endpoints that Terraform has not created yet. Prefer Entra
# authentication where the provider's storage operation supports it.
# Important: Runtime storage roles, DNS and private connectivity are still required;
# these settings neither authorize the Function identity nor make its endpoint public.
provider "azurerm" {
  features {
    storage {
      data_plane_available = false
    }
  }
  resource_provider_registrations = "none"
  storage_use_azuread             = true
}

# Purpose: Satisfy the reusable Storage module's generic ARM provider requirement.
# Evaluation: The module declares AzAPI for optional Table creation; this example
# requests no Tables. An empty provider config authenticates externally and creates nothing.
provider "azapi" {}