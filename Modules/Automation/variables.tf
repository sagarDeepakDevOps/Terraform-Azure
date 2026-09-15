variable "name" {
  type        = string
  description = "Azure Automation account name. No job schedule is created."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region supporting Automation."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}