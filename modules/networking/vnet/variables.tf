variable "name" {
  type        = string
  description = "Virtual network name."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "address_space" {
  type        = list(string)
  description = "Non-overlapping VNet CIDR ranges."
  validation {
    condition     = length(var.address_space) > 0 && alltrue([for cidr in var.address_space : can(cidrnetmask(cidr))])
    error_message = "Provide at least one valid IPv4 CIDR range."
  }
}

variable "dns_servers" {
  type        = list(string)
  description = "Custom DNS servers; an empty list uses Azure-provided DNS."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}