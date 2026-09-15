variable "prefix" {
  type        = string
  description = "Short naming prefix."
  default     = "aztfops"
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "eastus2"
}

variable "notification_email" {
  type        = string
  description = "Real operations contact for alerts and optional budgets."
  validation {
    condition     = can(regex("^[^@ ]+@[^@ ]+\\.[^@ ]+$", var.notification_email))
    error_message = "Provide a valid monitored email address."
  }
}

variable "enable_budget" {
  type        = bool
  description = "Create a resource group budget; requires billing permissions."
  default     = false
}

variable "budget_start_date" {
  type        = string
  description = "First day of the current or an allowed future month, YYYY-MM-01T00:00:00Z."
  default     = null
  validation {
    condition     = !var.enable_budget || can(regex("^[0-9]{4}-[0-9]{2}-01T00:00:00Z$", var.budget_start_date))
    error_message = "Set an explicit valid budget month before enabling the budget."
  }
}

variable "enable_lock" {
  type        = bool
  description = "Create a CanNotDelete resource group lock. Remove deliberately before destroying the lab."
  default     = false
}

variable "enable_sentinel" {
  type        = bool
  description = "Enable paid Microsoft Sentinel on the lab workspace."
  default     = false
}

variable "enable_subscription_defender" {
  type        = bool
  description = "Enable SUBSCRIPTION-WIDE paid Defender settings. Use only with explicit subscription-owner approval."
  default     = false
}

variable "enforce_policy" {
  type        = bool
  description = "Turn the resource group location policy from DoNotEnforce to enforced Deny."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Common resource tags."
  default     = { environment = "demo", project = "terraform-azure", managed_by = "terraform" }
}