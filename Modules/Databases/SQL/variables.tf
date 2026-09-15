variable "name" {
  type        = string
  description = "Globally unique Azure SQL logical server name."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "administrator_login" {
  type        = string
  description = "SQL authentication administrator. Configure Entra-only authentication for a production design."
  default     = "sqladmin"
}

variable "administrator_password" {
  type        = string
  description = "SQL administrator password; stored in Terraform state."
  sensitive   = true
}

variable "database_name" {
  type        = string
  description = "Application database name."
  default     = "appdb"
}

variable "sku_name" {
  type        = string
  description = "Database SKU. Basic is a small teaching SKU."
  default     = "Basic"
}

variable "max_size_gb" {
  type        = number
  description = "Database size compatible with the selected SKU. Basic supports at most 2 GiB."
  default     = 2
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}