variable "prefix" {
  type        = string
  description = "Prefixes every resource name in the lab. Use the same value in all eight exercises."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,22}[a-z0-9]$", var.prefix))
    error_message = "Use 3-24 lowercase letters, digits or hyphens, starting with a letter and ending alphanumeric."
  }
}

variable "location" {
  type        = string
  description = "Azure region. Every later exercise inherits this from the resource group, so it is set only here."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the resource group."
  default     = {}
}
