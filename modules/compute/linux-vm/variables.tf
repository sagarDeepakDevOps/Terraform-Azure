variable "name" {
  type        = string
  description = "Azure resource name of the VM; the NIC is named after it."
}

variable "computer_name" {
  type        = string
  description = "Hostname inside the OS."
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
  description = "Subnet for the NIC."
}

variable "private_ip_address" {
  type        = string
  description = "Static private IP inside the subnet; null lets Azure pick one."
  default     = null
}

variable "size" {
  type        = string
  description = "VM size. Check availability with az vm list-skus --location <region> --size Standard_D."
  default     = "Standard_D2ls_v7"
}

variable "admin_username" {
  type        = string
  description = "Login user. Password login is disabled."
  default     = "azureuser"
}

variable "ssh_public_key" {
  type        = string
  description = "OpenSSH RSA public key accepted for admin_username."
}

variable "install_apache" {
  type        = bool
  description = "Install Apache on first boot and serve a page naming the VM. Changing it replaces the VM."
  default     = false
}

variable "vnet_name" {
  type        = string
  description = "Hub or spoke the VM lives in, shown on the served page."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}
