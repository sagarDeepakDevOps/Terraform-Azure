variable "name" {
  type        = string
  description = "Globally unique Azure AI Search service name. Index schemas, ingestion and queries belong to application deployment."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Supported AI Search region."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}