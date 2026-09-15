variable "name" {
  type        = string
  description = "Globally unique PostgreSQL Flexible Server name."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "sku_name" {
  type        = string
  description = "PostgreSQL compute SKU. Burstable is for demonstration, not high availability."
  default     = "B_Standard_B1ms"
}

variable "administrator_password" {
  type        = string
  description = "PostgreSQL administrator password; stored in Terraform state."
  sensitive   = true
}

variable "subnet_id" {
  type        = string
  description = "Dedicated subnet delegated to Microsoft.DBforPostgreSQL/flexibleServers."
}

variable "private_dns_zone_id" {
  type        = string
  description = "VNet-linked zone ending in .postgres.database.azure.com."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}