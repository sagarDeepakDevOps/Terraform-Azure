variable "prefix" {
  type        = string
  description = "Short lowercase naming prefix."
  default     = "aztfmsg"
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,7}$", var.prefix))
    error_message = "Use 3-8 lowercase letters/digits, starting with a letter."
  }
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "eastus2"
}

variable "enable_api_management" {
  type        = bool
  description = "Enable the paid Developer API Management instance."
  default     = false
}

variable "publisher_email" {
  type        = string
  description = "Publisher contact, required when API Management is enabled."
  default     = null
  validation {
    condition     = !var.enable_api_management || can(regex("^[^@ ]+@[^@ ]+\\.[^@ ]+$", var.publisher_email))
    error_message = "Provide a valid publisher email before enabling API Management."
  }
}

variable "enable_workflow" {
  type        = bool
  description = "Enable scheduled Logic App executions."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Common resource tags."
  default     = { environment = "demo", project = "terraform-azure", managed_by = "terraform" }
}