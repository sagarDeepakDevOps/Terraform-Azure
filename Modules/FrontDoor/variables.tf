variable "name" {
  type        = string
  description = "Globally unique Front Door profile/endpoint name. Premium is required for the managed WAF rules shown here."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name; Front Door itself is global."
}

variable "origin_hostname" {
  type        = string
  description = "Backend FQDN serving HTTPS with a valid matching certificate."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}