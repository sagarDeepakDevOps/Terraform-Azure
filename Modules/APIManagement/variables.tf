variable "name" {
  type        = string
  description = "Globally unique API Management name. Developer tier has no production SLA and can take substantial time to provision."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "publisher_name" {
  type        = string
  description = "API publisher organization."
  default     = "Platform Team"
}

variable "publisher_email" {
  type        = string
  description = "Real monitored publisher contact address."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}