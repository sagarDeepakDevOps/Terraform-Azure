terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

resource "azurerm_automation_account" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  sku_name                     = "Basic"
  local_authentication_enabled = false
  tags                         = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_automation_runbook" "this" {
  name                    = "show-demo-context"
  resource_group_name     = var.resource_group_name
  location                = var.location
  automation_account_name = azurerm_automation_account.this.name
  log_verbose             = false
  log_progress            = true
  runbook_type            = "PowerShell"
  content                 = file("${path.module}/Show-DemoContext.ps1")
  tags                    = var.tags
}