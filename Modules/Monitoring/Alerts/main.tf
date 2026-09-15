terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

resource "azurerm_monitor_action_group" "this" {
  name                = "${var.name}-action"
  resource_group_name = var.resource_group_name
  short_name          = "tfalerts"
  tags                = var.tags

  email_receiver {
    name                    = "operations"
    email_address           = var.notification_email
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  scopes              = [var.target_resource_id]
  description         = "Investigate application server errors."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = var.metric_namespace
    metric_name      = var.metric_name
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = var.threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}