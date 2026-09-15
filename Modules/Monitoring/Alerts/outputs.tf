output "id" {
  description = "Metric alert ID."
  value       = azurerm_monitor_metric_alert.this.id
}

output "action_group_id" {
  description = "Action group ID for other alert rules."
  value       = azurerm_monitor_action_group.this.id
}