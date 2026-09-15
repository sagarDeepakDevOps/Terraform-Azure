variable "name" {
  type        = string
  description = "Log Analytics workspace name."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "retention_in_days" {
  type        = number
  description = "Workspace data retention."
  default     = 30
}

variable "daily_quota_gb" {
  type        = number
  description = "Daily ingestion cap. A cap can cause telemetry gaps and is not a billing guarantee."
  default     = 1
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}