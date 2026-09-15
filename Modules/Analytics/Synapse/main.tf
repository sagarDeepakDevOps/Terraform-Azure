terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

resource "azurerm_synapse_workspace" "this" {
  name                                 = var.name
  resource_group_name                  = var.resource_group_name
  location                             = var.location
  managed_resource_group_name          = "${var.name}-managed-rg"
  storage_data_lake_gen2_filesystem_id = var.filesystem_id
  sql_administrator_login              = "synapseadmin"
  sql_administrator_login_password     = var.administrator_password
  managed_virtual_network_enabled      = true
  public_network_access_enabled        = false
  tags                                 = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "storage" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.this.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}