variable "name" {
  type        = string
  description = "Storage system topic name."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Region of the source storage account."
}

variable "storage_account_id" {
  type        = string
  description = "StorageV2 source account with an incoming container."
}

variable "service_bus_queue_id" {
  type        = string
  description = "Queue accepting Event Grid identity-based delivery."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}