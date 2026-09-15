variable "name" {
  type        = string
  description = "Linux virtual machine scale set name."
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
  description = "VM size for scale set instances."
  default     = "Standard_B2s"
}

variable "subnet_id" {
  type        = string
  description = "Workload subnet with explicit egress."
}

variable "backend_pool_id" {
  type        = string
  description = "Standard load balancer backend pool ID."
}

variable "ssh_public_key" {
  type        = string
  description = "Administrator SSH public key."
}

variable "custom_data" {
  type        = string
  description = "Base64 cloud-init used for every scale set instance."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}