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

variable "sku" {
  type        = string
  description = "Basic connects from the portal only. Standard adds native-client SSH from your terminal. Both reach VMs in peered spokes."
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.sku)
    error_message = "sku must be Basic or Standard."
  }
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet named AzureBastionSubnet, at least /26."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}
