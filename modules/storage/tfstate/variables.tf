variable "resource_group_name" {
  type        = string
  description = "Existing resource group. Use one that holds nothing else, so tearing the lab down cannot take the state with it."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "name_prefix" {
  type        = string
  description = "Base for the generated storage account name. Hyphens are stripped and a random tail added, because the name must be globally unique."
}

variable "storage_account_name" {
  type        = string
  description = "Exact storage account name, overriding the generated one. Must be globally unique."
  default     = null

  validation {
    condition     = var.storage_account_name == null ? true : can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account names are 3-24 characters, lowercase letters and digits only."
  }
}

variable "container_name" {
  type        = string
  description = "Blob container holding one state file per configuration."
  default     = "tfstate"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.container_name))
    error_message = "Container names are 3-63 characters of lowercase letters, digits and hyphens, and cannot start or end with a hyphen."
  }
}

variable "replication_type" {
  type        = string
  description = "LRS keeps three copies in one datacentre and is enough for a lab. State you cannot lose belongs in ZRS or GRS."
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "Use one of LRS, ZRS, GRS, RAGRS, GZRS or RAGZRS."
  }
}

variable "retention_days" {
  type        = number
  description = "How long a deleted blob or container can still be recovered."
  default     = 7

  validation {
    condition     = var.retention_days >= 1 && var.retention_days <= 365
    error_message = "Retention must be between 1 and 365 days."
  }
}

variable "shared_access_key_enabled" {
  type        = bool
  description = "True lets the backend fetch an account key, which works for any subscription Contributor. False is stricter and forces the backend to use use_azuread_auth."
  default     = true
}

variable "grant_current_user_blob_access" {
  type        = bool
  description = "Give whoever runs this apply Storage Blob Data Contributor on the container, which is what use_azuread_auth needs. Creating a role assignment itself requires Owner or User Access Administrator."
  default     = false
}

variable "allowed_ip_ranges" {
  type        = list(string)
  description = "Public addresses allowed to reach the account. Empty means no firewall. Azure rejects private ranges and /31 or /32 suffixes, so give a bare address."
  default     = []
}

variable "enable_delete_lock" {
  type        = bool
  description = "Add a CanNotDelete lock. It also blocks terraform destroy on this configuration until you set it back to false and apply."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}
