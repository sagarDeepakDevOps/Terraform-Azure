variable "name" {
  type        = string
  description = "Linux VM name."
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
  description = "Workload subnet with an NSG and explicit egress for cloud-init packages."
}

variable "size" {
  type        = string
  description = "VM size; confirm regional capacity and quota before applying."
  default     = "Standard_B2s"
}

variable "admin_username" {
  type        = string
  description = "Local administrator username."
  default     = "azureuser"
}

variable "ssh_public_key" {
  type        = string
  description = "An SSH public key, never a private key."
}

variable "custom_data" {
  type        = string
  description = "Base64-encoded cloud-init. Do not put credentials in custom data."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}