variable "name" {
  type        = string
  description = "Unique Azure OpenAI account name and custom subdomain."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Region supporting the chosen model versions and deployment SKUs."
}

variable "deployments" {
  type = map(object({
    model_name    = string
    model_version = string
    sku_name      = optional(string, "GlobalStandard")
    capacity      = optional(number, 1)
  }))
  description = "Explicit model deployments. Verify model lifecycle, regional availability, data residency and quota before applying. Empty creates only the account."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}