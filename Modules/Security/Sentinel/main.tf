terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Enable Microsoft Sentinel capabilities on the chosen Log Analytics workspace.
# Creation: AzureRM onboards workspace_id to Sentinel; a created workspace output
# establishes the prerequisite ordering. The calling example makes this paid step opt-in.
# Important: Onboarding does not configure data connectors, detection rules, incident
# automation or a SOC response process. Plan ingestion/security costs and required
# permissions before enabling the service; resource creation is not complete security coverage.
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "this" {
  workspace_id = var.workspace_id
}