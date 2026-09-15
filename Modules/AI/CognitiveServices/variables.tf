variable "name" {
  type        = string
  description = "Unique multi-service Azure AI account name and custom subdomain. Some capabilities require additional service eligibility."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Supported AI Services region."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}