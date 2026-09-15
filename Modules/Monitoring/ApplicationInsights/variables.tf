variable "name" {
  type        = string
  description = "Workspace-based Application Insights name."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "workspace_id" {
  type        = string
  description = "Log Analytics workspace ARM ID."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}