variable "name" {
  type        = string
  description = "Diagnostic setting name."
  default     = "send-to-log-analytics"
}

variable "target_resource_id" {
  type        = string
  description = "Resource emitting platform logs/metrics. Verify its supported categories first."
}

variable "workspace_id" {
  type        = string
  description = "Destination Log Analytics workspace ARM ID."
}

variable "log_category_groups" {
  type        = set(string)
  description = "Supported log category groups, typically allLogs or audit. Empty disables log export."
  default     = ["allLogs"]
}

variable "metric_categories" {
  type        = set(string)
  description = "Supported metric categories. Empty disables metric export."
  default     = ["AllMetrics"]
}