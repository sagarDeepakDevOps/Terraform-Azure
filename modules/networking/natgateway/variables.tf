variable "name" {
  type        = string
  description = "NAT gateway name; also prefixes its public IP."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region. The gateway is zonal only if given a zone, which this module does not set."
}

variable "subnet_ids" {
  type        = map(string)
  description = "Subnets routed through this gateway, keyed by stable names."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}
