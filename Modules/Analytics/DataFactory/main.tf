terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

resource "azurerm_data_factory" "this" {
  name                            = var.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  managed_virtual_network_enabled = true
  public_network_enabled          = false
  tags                            = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_data_factory_integration_runtime_azure" "this" {
  name                    = "managed-vnet"
  data_factory_id         = azurerm_data_factory.this.id
  location                = var.location
  virtual_network_enabled = true
  time_to_live_min        = 0
}

resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "this" {
  name                     = "data-lake"
  data_factory_id          = azurerm_data_factory.this.id
  url                      = var.storage_dfs_endpoint
  use_managed_identity     = true
  integration_runtime_name = azurerm_data_factory_integration_runtime_azure.this.name
}

resource "azurerm_data_factory_managed_private_endpoint" "this" {
  for_each           = toset(["dfs", "blob"])
  name               = "lake-${each.key}"
  data_factory_id    = azurerm_data_factory.this.id
  target_resource_id = var.storage_account_id
  subresource_name   = each.key
}

resource "azurerm_role_assignment" "storage" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.this.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_data_factory_pipeline" "this" {
  name            = "demo-pipeline"
  data_factory_id = azurerm_data_factory.this.id
  activities_json = jsonencode([{
    name           = "WaitForDemo"
    type           = "Wait"
    typeProperties = { waitTimeInSeconds = 1 }
  }])
}