variable "name" {
  type        = string
  description = "Private DNS zone name, such as privatelink.blob.core.windows.net."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "virtual_network_ids" {
  type        = map(string)
  description = "VNet links keyed by stable names. Peering does not share DNS zone links."
}

variable "registration_enabled" {
  type        = bool
  description = "VM autoregistration; leave false for privatelink zones."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}