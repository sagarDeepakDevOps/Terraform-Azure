variable "name" {
  type        = string
  description = "Standard public load balancer name."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "backend_nic_ids" {
  type        = map(string)
  description = "VM NICs with an IP configuration named primary, keyed by plan-time known names. All of them must be in one VNet."
  default     = {}
}

variable "domain_name_label" {
  type        = string
  description = "Optional DNS label for the frontend, producing <label>.<region>.cloudapp.azure.com. Must be unique across the whole region."
  default     = null
}

variable "frontend_port" {
  type        = number
  description = "Public TCP port for the HTTP demonstration. Production should use TLS."
  default     = 80
}

variable "backend_port" {
  type        = number
  description = "HTTP backend and probe port."
  default     = 80
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}
