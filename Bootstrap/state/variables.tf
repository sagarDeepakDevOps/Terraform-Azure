variable "prefix" {
  type        = string
  description = "Short lowercase prefix for state infrastructure."
  default     = "aztfst"
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,7}$", var.prefix))
    error_message = "Use 3-8 lowercase letters/digits, starting with a letter."
  }
}

variable "location" {
  type        = string
  description = "State storage region."
  default     = "eastus2"
}

variable "runner_public_ip_addresses" {
  type        = list(string)
  description = "Trusted public IPv4 addresses or CIDRs. For one address use a bare IP, not /32. Avoid broad shared-hosted runner ranges."
  validation {
    condition     = length(var.runner_public_ip_addresses) > 0 && !contains(var.runner_public_ip_addresses, "0.0.0.0/0")
    error_message = "Provide explicitly trusted runner addresses; do not allow the whole Internet."
  }
}

variable "state_principals" {
  type = map(object({
    object_id      = string
    principal_type = string
  }))
  description = "Backend writers keyed by name. Types: User, Group or ServicePrincipal. Include the bootstrap operator before migrating any state."
  validation {
    condition     = length(var.state_principals) > 0 && alltrue([for principal in var.state_principals : contains(["User", "Group", "ServicePrincipal"], principal.principal_type)])
    error_message = "Supply at least one backend writer with a supported principal type."
  }
}

variable "tags" {
  type        = map(string)
  description = "State infrastructure ownership tags."
  default     = { environment = "shared", project = "terraform-azure", managed_by = "terraform" }
}