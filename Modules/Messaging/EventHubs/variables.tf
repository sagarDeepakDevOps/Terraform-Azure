variable "name" {
  type        = string
  description = "Globally unique Event Hubs namespace name. This demo uses an Entra-authenticated public endpoint."
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