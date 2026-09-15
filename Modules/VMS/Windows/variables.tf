variable "name" {
  type        = string
  description = "Windows VM Azure resource name."
}

variable "computer_name" {
  type        = string
  description = "Windows hostname, at most 15 characters."
  default     = "windemo"
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
  description = "Private workload subnet ID."
}

variable "size" {
  type        = string
  description = "Windows VM size."
  default     = "Standard_B2s"
}

variable "admin_username" {
  type        = string
  description = "Local administrator username."
  default     = "azureadmin"
}

variable "admin_password" {
  type        = string
  description = "Windows administrator password. Sensitive values are still stored in Terraform state."
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}