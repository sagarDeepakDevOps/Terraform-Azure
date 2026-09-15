variable "name" {
  type        = string
  description = "Metric alert name."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "target_resource_id" {
  type        = string
  description = "Resource that emits the selected metric."
}

variable "notification_email" {
  type        = string
  description = "Monitored operations email address."
}

variable "metric_namespace" {
  type        = string
  description = "Metric resource namespace."
  default     = "Microsoft.Web/sites"
}

variable "metric_name" {
  type        = string
  description = "Metric aggregated as Total over five minutes."
  default     = "Http5xx"
}

variable "threshold" {
  type        = number
  description = "Trigger when total metric count exceeds this value."
  default     = 5
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}