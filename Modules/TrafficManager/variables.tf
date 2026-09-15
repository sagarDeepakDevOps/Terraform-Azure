variable "name" {
  type        = string
  description = "Globally unique priority-routing profile name. Traffic Manager is DNS routing, not a reverse proxy."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "endpoints" {
  type = map(object({
    hostname = string
    priority = number
  }))
  description = "At least two independently deployed, healthy HTTPS application endpoints. Lower priority number wins."
  validation {
    condition     = length(var.endpoints) >= 2 && length(distinct([for endpoint in var.endpoints : endpoint.priority])) == length(var.endpoints)
    error_message = "Supply at least two endpoints with unique priorities."
  }
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}