variable "name" {
  type        = string
  description = "Globally unique alphanumeric registry name."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "sku" {
  type        = string
  description = "Basic demo registry, Standard, or Premium. Private endpoints require Premium."
  default     = "Basic"
}

variable "public_network_access_enabled" {
  type        = bool
  description = "An authenticated public endpoint is used by the Basic demo. For private access use Premium plus a registry private endpoint."
  default     = true
  validation {
    condition     = var.public_network_access_enabled || var.sku == "Premium"
    error_message = "Select Premium and configure private connectivity before disabling public registry access."
  }
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}