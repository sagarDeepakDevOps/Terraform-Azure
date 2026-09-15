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
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "this" {
  name                                           = var.name
  resource_group_name                            = var.resource_group_name
  location                                       = var.location
  service_plan_id                                = azurerm_service_plan.this.id
  https_only                                     = true
  virtual_network_subnet_id                      = var.integration_subnet_id
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  app_settings                                   = var.app_settings
  tags                                           = var.tags

  site_config {
    always_on                     = true
    minimum_tls_version           = "1.2"
    scm_minimum_tls_version       = "1.2"
    ftps_state                    = "Disabled"
    http2_enabled                 = true
    vnet_route_all_enabled        = var.integration_subnet_id != null
    ip_restriction_default_action = var.front_door_only ? "Deny" : "Allow"

    application_stack {
      node_version = "22-lts"
    }

    dynamic "ip_restriction" {
      for_each = var.front_door_only ? [true] : []
      content {
        name        = "front-door-only"
        priority    = 100
        action      = "Allow"
        service_tag = "AzureFrontDoor.Backend"
        headers {
          x_azure_fdid = [var.front_door_id]
        }
      }
    }
  }

  identity {
    type = "SystemAssigned"
  }
}