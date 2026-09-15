terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

resource "azurerm_service_plan" "this" {
  name                = "${var.name}-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "FC1"
  tags                = var.tags
}

resource "azurerm_function_app_flex_consumption" "this" {
  name                                           = var.name
  resource_group_name                            = var.resource_group_name
  location                                       = var.location
  service_plan_id                                = azurerm_service_plan.this.id
  storage_container_type                         = "blobContainer"
  storage_container_endpoint                     = var.storage_container_endpoint
  storage_authentication_type                    = "UserAssignedIdentity"
  storage_user_assigned_identity_id              = var.identity_id
  runtime_name                                   = "node"
  runtime_version                                = "22"
  maximum_instance_count                         = 40
  instance_memory_in_mb                          = 2048
  https_only                                     = true
  virtual_network_subnet_id                      = var.integration_subnet_id
  webdeploy_publish_basic_authentication_enabled = false
  tags                                           = var.tags

  app_settings = {
    AzureWebJobsStorage__accountName = var.storage_account_name
    AzureWebJobsStorage__credential  = "managedidentity"
    AzureWebJobsStorage__clientId    = var.identity_client_id
  }

  site_config {
    minimum_tls_version                    = "1.2"
    scm_minimum_tls_version                = "1.2"
    application_insights_connection_string = var.application_insights_connection_string
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }
}