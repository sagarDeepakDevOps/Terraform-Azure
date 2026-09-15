terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create the managed Automation account that hosts operational runbooks.
# Creation: AzureRM provisions Basic Automation with a system-assigned identity and
# disables local authentication. The runbook below references this account by name.
# Important: The identity has no Azure management permissions until roles are granted.
# This sample does not create a Hybrid Runbook Worker, schedule or automatic job.
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

# Purpose: Publish a small PowerShell runbook that demonstrates managed operational code.
# Creation: Terraform reads Show-DemoContext.ps1 from this module and Azure stores
# it as show-demo-context under the newly created Automation account. Progress logs
# are enabled while verbose logging is disabled.
# Runtime: Azure executes the script only when a run is requested; Terraform does
# not execute PowerShell during provisioning. This script emits a demo status object
# without external modules or credentials, and no recurring job is attached here.
# Important: Real runbooks need a supported runtime, explicit permissions, tested
# failure handling and careful logging that does not expose secrets.
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