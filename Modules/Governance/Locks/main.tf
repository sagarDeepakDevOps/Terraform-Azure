terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

resource "azurerm_management_lock" "this" {
  name       = var.name
  scope      = var.scope
  lock_level = "CanNotDelete"
  notes      = "Remove deliberately before deleting protected resources. This is not a data-plane backup."
}