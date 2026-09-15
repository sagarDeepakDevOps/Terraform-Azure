variable "name" {
  type        = string
  description = "Globally unique Data Factory name. A Wait pipeline demonstrates orchestration without moving customer data."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "storage_account_id" {
  type        = string
  description = "Data lake account ID. Approve the two managed private endpoint requests on this account before data access."
}

variable "storage_dfs_endpoint" {
  type        = string
  description = "ADLS Gen2 DFS endpoint URL."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}