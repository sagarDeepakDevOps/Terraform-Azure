terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

resource "azurerm_machine_learning_workspace" "this" {
  name                           = var.name
  resource_group_name            = var.resource_group_name
  location                       = var.location
  application_insights_id        = var.application_insights_id
  key_vault_id                   = var.key_vault_id
  storage_account_id             = var.storage_account_id
  storage_account_access_type    = "Identity"
  primary_user_assigned_identity = var.identity_id
  public_network_access_enabled  = false
  friendly_name                  = "Terraform ML demo"
  tags                           = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  managed_network {
    isolation_mode                = "AllowInternetOutbound"
    provision_on_creation_enabled = false
  }
}