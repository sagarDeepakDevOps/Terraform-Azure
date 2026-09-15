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

provider "azapi" {}