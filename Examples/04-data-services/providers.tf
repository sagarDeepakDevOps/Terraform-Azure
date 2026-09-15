# Purpose: Configure the inherited AzureRM client for private data infrastructure.
# Authentication: Use external CLI/federated identity plus ARM_SUBSCRIPTION_ID;
# pre-register the namespaces required by the selected database engines.
# Storage: Skip AzureRM 4.x data-plane availability probes while private accounts
# and their endpoints are being created. The module uses ARM child-resource forms;
# storage_use_azuread requests Entra auth for supported storage operations.
# Recovery: Do not automatically purge soft-deleted Key Vaults on Terraform destroy.
# Important: These are provider behaviors, not a bypass of data RBAC or private DNS.
# Mocked tests use fake providers and perform no real database/account deployment.
provider "azurerm" {
  features {
    storage {
      data_plane_available = false
    }
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
  resource_provider_registrations = "none"
  storage_use_azuread             = true
}

# Purpose: Supply Azure's generic ARM API client for the Storage Tables resource.
# Creation: AzAPI uses the same externally selected Azure subscription/identity;
# the Storage module's explicit API type/version defines the actual Table request.
# Important: This avoids enabling shared keys for Table creation; it grants no data access.
provider "azapi" {}