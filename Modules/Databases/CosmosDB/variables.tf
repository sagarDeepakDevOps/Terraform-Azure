variable "name" {
  type        = string
  description = "Globally unique Cosmos DB for NoSQL account name."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name."
}

variable "location" {
  type        = string
  description = "Single serverless region for this example."
}

variable "principal_id" {
  type        = string
  description = "Application identity object ID receiving the Cosmos DB Built-in Data Contributor role."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}