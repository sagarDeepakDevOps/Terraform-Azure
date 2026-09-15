terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create the managed Consumption Logic App that owns the demo workflow.
# Creation: AzureRM provisions the workflow with a system-assigned identity and the
# caller's enabled flag; trigger/action resources below attach to its ARM ID.
# Important: It defaults to disabled through the module input to avoid unattended
# scheduled executions. An identity alone grants no connector/data access, and
# enabling the workflow can produce billable runs/actions.
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

# Purpose: Define a once-per-day trigger for the demonstration workflow.
# Creation: Attach a Day-frequency, interval-1 recurrence trigger to the new Logic
# App using its resource ID. Azure schedules runs only when the workflow is enabled.
# Important: This is a schedule, not a webhook endpoint or a manually published event.
# Review timing and costs before turning on recurrence for a real integration.
resource "azurerm_logic_app_trigger_recurrence" "this" {
  name         = "daily"
  logic_app_id = azurerm_logic_app_workflow.this.id
  frequency    = "Day"
  interval     = 1
}

# Purpose: Give each workflow run an actual Compose action that emits a status object.
# Creation: jsonencode turns the Terraform object into the Logic Apps action JSON,
# and Azure stores it under the created workflow. @utcNow() is evaluated by the
# Logic Apps runtime during execution, not by Terraform during plan or apply.
# Important: This example makes no external calls and needs no connector credentials;
# useful business processing and action dependencies must be designed separately.
resource "azurerm_logic_app_action_custom" "this" {
  name         = "compose-status"
  logic_app_id = azurerm_logic_app_workflow.this.id
  body = jsonencode({
    type   = "Compose"
    inputs = { status = "Azure Terraform workflow demo", timestamp = "@utcNow()" }
  })
}