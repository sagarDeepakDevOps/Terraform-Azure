variable "name" {
  type        = string
  description = "Private endpoint name."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "subnet_id" {
  type        = string
  description = "Non-delegated private endpoint subnet ID."
}

variable "resource_id" {
  type        = string
  description = "Target Azure resource ID. Disable public access on that resource separately."
}

variable "subresource_names" {
  type        = list(string)
  description = "Target group IDs such as blob, vault, sqlServer, or sites."
}

variable "private_dns_zone_ids" {
  type        = list(string)
  description = "Matching service private DNS zone IDs, already linked to client VNets."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}