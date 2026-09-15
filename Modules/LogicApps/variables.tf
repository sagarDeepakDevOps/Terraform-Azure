variable "name" {
  type        = string
  description = "Consumption Logic App name. A daily trigger and Compose action demonstrate a complete workflow without external credentials."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "enabled" {
  type        = bool
  description = "Enable workflow execution; disabled initially to avoid unattended scheduled runs."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}