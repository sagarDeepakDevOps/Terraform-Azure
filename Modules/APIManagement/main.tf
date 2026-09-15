terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

resource "azurerm_api_management" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = "Developer_1"
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }

  security {
    frontend_tls10_enabled = false
    frontend_tls11_enabled = false
    backend_tls10_enabled  = false
    backend_tls11_enabled  = false
    frontend_ssl30_enabled = false
    backend_ssl30_enabled  = false
  }
}

resource "azurerm_api_management_api" "this" {
  name                  = "demo"
  resource_group_name   = var.resource_group_name
  api_management_name   = azurerm_api_management.this.name
  revision              = "1"
  display_name          = "Terraform Demo API"
  path                  = "demo"
  protocols             = ["https"]
  subscription_required = true
}

resource "azurerm_api_management_api_operation" "health" {
  operation_id        = "health"
  api_name            = azurerm_api_management_api.this.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  display_name        = "Health"
  method              = "GET"
  url_template        = "/health"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "this" {
  api_name            = azurerm_api_management_api.this.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  operation_id        = azurerm_api_management_api_operation.health.operation_id
  xml_content         = file("${path.module}/health-policy.xml")
}

resource "azurerm_api_management_product" "this" {
  product_id            = "demo"
  api_management_name   = azurerm_api_management.this.name
  resource_group_name   = var.resource_group_name
  display_name          = "Demo APIs"
  subscription_required = true
  approval_required     = true
  published             = true
}

resource "azurerm_api_management_product_api" "this" {
  api_name            = azurerm_api_management_api.this.name
  product_id          = azurerm_api_management_product.this.product_id
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
}