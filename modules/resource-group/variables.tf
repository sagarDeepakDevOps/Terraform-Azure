variable "name" {
  type        = string
  description = "Resource group name."
}

variable "location" {
  type        = string
  description = "Azure region; every resource inherits it."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}
