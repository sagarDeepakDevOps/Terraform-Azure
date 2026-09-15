variable "name" {
  type        = string
  description = "Recovery Services vault name."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Region shared by the vault and protected VMs."
}

variable "virtual_machine_ids" {
  type        = map(string)
  description = "VMs to protect, keyed by stable names."
}

variable "retention_days" {
  type        = number
  description = "Number of daily recovery points."
  default     = 7
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}