terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create the central log store used by the selected lab's telemetry services.
# Creation: AzureRM provisions a PerGB2018 workspace with the requested retention
# and daily ingestion quota, then exposes its ARM ID to diagnostic settings,
# Application Insights, Container Apps or AKS integrations that explicitly use it.
# Important: Workspace creation does not install agents or collect every resource's
# logs automatically. ARM id and workspace_id/customer GUID are different identifiers.
# Ingestion/retention are billable; a daily quota can drop telemetry and is not a
# guaranteed spending ceiling. Define access, retention and alerting for real data.
resource "azurerm_log_analytics_workspace" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days
  daily_quota_gb      = var.daily_quota_gb
  tags                = var.tags
}