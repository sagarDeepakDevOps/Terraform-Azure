terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

resource "azurerm_logic_app_workflow" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  enabled             = var.enabled
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_logic_app_trigger_recurrence" "this" {
  name         = "daily"
  logic_app_id = azurerm_logic_app_workflow.this.id
  frequency    = "Day"
  interval     = 1
}

resource "azurerm_logic_app_action_custom" "this" {
  name         = "compose-status"
  logic_app_id = azurerm_logic_app_workflow.this.id
  body = jsonencode({
    type   = "Compose"
    inputs = { status = "Azure Terraform workflow demo", timestamp = "@utcNow()" }
  })
}