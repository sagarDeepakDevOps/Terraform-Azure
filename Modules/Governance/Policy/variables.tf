variable "resource_group_id" {
  type        = string
  description = "Resource group scope for the built-in Allowed locations policy."
}

variable "allowed_locations" {
  type        = list(string)
  description = "Approved Azure location names."
}

variable "enforce" {
  type        = bool
  description = "Enable Deny enforcement only after evaluating compliance. False uses DoNotEnforce for the assignment."
  default     = false
}