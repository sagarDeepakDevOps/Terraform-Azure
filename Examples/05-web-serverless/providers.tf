provider "azurerm" {
  features {
    storage {
      data_plane_available = false
    }
  }
  resource_provider_registrations = "none"
  storage_use_azuread             = true
}

provider "azapi" {}