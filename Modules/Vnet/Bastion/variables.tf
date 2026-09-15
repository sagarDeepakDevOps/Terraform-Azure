variable "name" {
  type        = string
  description = "Bastion host name."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "subnet_id" {
  type        = string
  description = "AzureBastionSubnet ID with a /26 or larger address range."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}