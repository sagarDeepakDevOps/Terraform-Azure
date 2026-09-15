variable "name" {
  type        = string
  description = "Managed Redis instance name. This uses Azure Managed Redis, not the legacy Azure Cache for Redis resource."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "A region offering Azure Managed Redis."
}

variable "sku_name" {
  type        = string
  description = "Managed Redis SKU. This single-node, non-HA configuration is for demonstration only."
  default     = "Balanced_B0"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}