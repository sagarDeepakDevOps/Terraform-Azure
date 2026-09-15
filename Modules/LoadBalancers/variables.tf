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
  description = "VM NICs with an IP configuration named primary. VMSS attaches its own pool membership."
  default     = {}
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