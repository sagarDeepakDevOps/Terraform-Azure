variable "name" {
  type        = string
  description = "NAT gateway name."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "subnet_ids" {
  type        = map(string)
  description = "Workload subnets that need explicit outbound Internet access."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}