# Root inputs are passed to child modules by main.tf. Defaults allow a small
# credential-free mocked plan; a live deployment still needs Azure authentication.
# Override non-secret values in a local terraform.tfvars file or through TF_VAR_*
# environment variables. The tracked .example file is not loaded automatically.

variable "prefix" {
  type        = string
  description = "3-12 lowercase letters/digits starting with a letter; names this root's resources independently of the numbered examples."
  default     = "aztfroot"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,11}$", var.prefix))
    error_message = "Use 3-12 lowercase letters or digits, starting with a letter."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the resource group metadata, VNet and NSG."
  default     = "eastus2"
}

variable "vnet_cidr" {
  type        = string
  description = "IPv4 CIDR for this starter VNet; avoid overlap with networks you may connect later."
  default     = "10.120.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vnet_cidr))
    error_message = "Provide a valid IPv4 CIDR for the VNet."
  }
}

variable "workload_subnet_cidr" {
  type        = string
  description = "IPv4 subnet CIDR within vnet_cidr; keep the two inputs consistent when changing address space."
  default     = "10.120.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.workload_subnet_cidr))
    error_message = "Provide a valid IPv4 CIDR for the workload subnet."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags passed to all taggable resources in the three starter modules."
  default = {
    environment = "demo"
    project     = "terraform-azure"
    example     = "root-starter"
    managed_by  = "terraform"
  }
}