variable "name" {
  type        = string
  description = "Globally unique Key Vault name, 3-24 characters. Purge protection prevents immediate name reuse after deletion."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "tenant_id" {
  type        = string
  description = "Microsoft Entra tenant ID."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}