variable "prefix" {
  type        = string
  description = "3-8 lowercase letters/digits, starting with a letter. Random suffixes make service names unique."
  default     = "aztfdata"
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,7}$", var.prefix))
    error_message = "Use 3-8 lowercase letters or digits, starting with a letter."
  }
}

variable "location" {
  type        = string
  description = "Azure region; verify database SKU availability."
  default     = "eastus2"
}

variable "databases" {
  type = object({
    sql        = optional(bool, true)
    postgresql = optional(bool, false)
    mysql      = optional(bool, false)
    cosmos     = optional(bool, false)
    redis      = optional(bool, false)
  })
  description = "Choose database engines to create. Each enabled engine incurs independent charges."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Common resource tags."
  default     = { environment = "demo", project = "terraform-azure", managed_by = "terraform" }
}