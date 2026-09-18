variable "prefix" {
  type        = string
  description = "Prefixes every group name. Must differ from the prefix the numbered exercises and full-lab use, so this demo cannot collide with them."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,22}[a-z0-9]$", var.prefix))
    error_message = "Use 3-24 lowercase letters, digits or hyphens, starting with a letter and ending alphanumeric."
  }
}

variable "location" {
  type        = string
  description = "Default region for groups that do not name one of their own."
}

variable "resource_groups" {
  type = map(object({
    location = optional(string)
    tags     = optional(map(string), {})
  }))
  description = "Groups to create, keyed by short name. Each becomes <prefix>-<key>-rg. More than one is useful here only because it makes terraform state list worth looking at."

  validation {
    condition     = length(var.resource_groups) > 0
    error_message = "Declare at least one resource group, or there is nothing to put in the state."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every group, merged with each group's own tags."
  default     = {}
}
