# No backend block here, and there never will be one. This configuration creates
# the storage the other backends point at, so its own state stays local.
terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.81.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}
