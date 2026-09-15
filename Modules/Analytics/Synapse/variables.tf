variable "name" {
  type        = string
  description = "Globally unique Synapse workspace name. No dedicated SQL or Spark pool is created."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "filesystem_id" {
  type        = string
  description = "DFS filesystem URL, such as https://account.dfs.core.windows.net/synapse; not a blob container ARM ID."
}

variable "storage_account_id" {
  type        = string
  description = "Data lake ARM ID for workspace data access."
}

variable "administrator_password" {
  type        = string
  description = "Demo SQL administrator password; stored in state. Configure Entra authentication for production."
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}