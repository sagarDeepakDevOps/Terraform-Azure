terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Define the operations notification destination used by the metric alert.
# Creation: AzureRM creates an action group with the configured email receiver and
# common alert schema. The rule below references its ID after the group exists.
# Important: Supply a real monitored mailbox and validate receipt/response procedures.
# Creating an action group alone does not monitor a metric or resolve incidents.
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

# Purpose: Notify operations when the selected resource exceeds an error-count threshold.
# Creation: Create a severity-2 alert on target_resource_id, evaluate once per minute,
# and compare the metric's five-minute Total with var.threshold using GreaterThan.
# The action_group_id reference connects qualifying alerts to the email group above.
# Important: The target must emit the chosen metric namespace/name with supported
# aggregation. This is an Azure Monitor metric alert, not a Log Analytics query or
# an application health fix. Review alert costs, noise and incident ownership.
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