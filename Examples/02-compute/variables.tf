variable "prefix" {
  type        = string
  description = "Resource naming prefix."
  default     = "aztfvm"
}

variable "location" {
  type        = string
  description = "Azure region; verify VM quota and SKU availability."
  default     = "eastus2"
}

variable "ssh_public_key" {
  type        = string
  description = "Your SSH public key. Set TF_VAR_ssh_public_key from a local .pub file."
}

variable "enable_windows" {
  type        = bool
  description = "Create an additional Windows Server VM."
  default     = false
}

variable "windows_admin_password" {
  type        = string
  description = "Required when Windows is enabled. Supply using TF_VAR_windows_admin_password."
  sensitive   = true
  default     = null
  validation {
    condition     = !var.enable_windows || try(length(var.windows_admin_password) >= 16, false)
    error_message = "Supply a complex Windows password of at least 16 characters when enabling Windows."
  }
}

variable "enable_scale_set" {
  type        = bool
  description = "Add a 1-3 instance autoscaling Linux VM scale set."
  default     = false
}

variable "enable_backup" {
  type        = bool
  description = "Protect Linux VMs with Azure Backup; soft-deleted backups affect cleanup."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Common resource tags."
  default     = { environment = "demo", project = "terraform-azure", managed_by = "terraform" }
}