variable "name" {
  type        = string
  description = "Deletion lock name."
  default     = "protect-from-deletion"
}

variable "scope" {
  type        = string
  description = "Resource or resource group ARM ID."
}