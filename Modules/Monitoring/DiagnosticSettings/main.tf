terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Export selected Azure platform logs/metrics from one resource to Log Analytics.
# Creation: Bind target_resource_id to workspace_id and expand the caller's log
# category groups and metric categories into enabled blocks. Empty sets omit that
# kind of export. Dedicated requests resource-specific destination tables where supported.
# References to created targets/workspaces provide the required deployment ordering.
# Important: Categories are service-specific; not every target supports allLogs or
# AllMetrics. This is not guest/application instrumentation, and it does not export
# all resources in a subscription. Ingestion costs and workspace retention still apply.
resource "azurerm_monitor_diagnostic_setting" "this" {
  name                           = var.name
  target_resource_id             = var.target_resource_id
  log_analytics_workspace_id     = var.workspace_id
  log_analytics_destination_type = "Dedicated"

  dynamic "enabled_log" {
    for_each = var.log_category_groups
    content {
      category_group = enabled_log.value
    }
  }

  dynamic "enabled_metric" {
    for_each = var.metric_categories
    content {
      category = enabled_metric.value
    }
  }
}