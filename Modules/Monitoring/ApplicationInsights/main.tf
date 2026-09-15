terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Provide workspace-based application telemetry for requests, failures and
# other instrumented application events.
# Creation: AzureRM links this web Application Insights component to the caller's
# Log Analytics ARM ID and configures 20% sampling. Its connection-string output is
# passed to applications/Functions so their supported instrumentation can report.
# Important: Creating the component or setting a connection string does not by
# itself add every required SDK/agent to an application. Sampling affects detail,
# telemetry ingestion is billable, and logs must not contain customer secrets.
resource "azurerm_application_insights" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  workspace_id        = var.workspace_id
  application_type    = "web"
  sampling_percentage = 20
  tags                = var.tags
}