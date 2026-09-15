variable "name" {
  type        = string
  description = "Globally unique Flex Consumption Function App name, at most 32 characters."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Region supporting Flex Consumption and the selected runtime."
}

variable "storage_account_name" {
  type        = string
  description = "Host storage account name. The identity needs blob, queue and table data roles."
}

variable "storage_container_endpoint" {
  type        = string
  description = "HTTPS URL of an existing deployment blob container."
}

variable "identity_id" {
  type        = string
  description = "User-assigned identity ARM ID with access to host and deployment storage."
}

variable "identity_client_id" {
  type        = string
  description = "Client ID of the same user-assigned identity."
}

variable "integration_subnet_id" {
  type        = string
  description = "Subnet delegated to Microsoft.App/environments with private storage DNS and explicit egress."
}

variable "application_insights_connection_string" {
  type        = string
  description = "Application Insights connection string."
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}