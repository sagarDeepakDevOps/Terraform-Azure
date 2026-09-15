variable "name" {
  type        = string
  description = "Globally unique Service Bus namespace name. Standard exposes an authenticated public endpoint; private networking requires a Premium design."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}