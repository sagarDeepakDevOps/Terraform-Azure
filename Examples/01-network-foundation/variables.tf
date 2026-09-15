variable "prefix" {
  type        = string
  description = "Short lowercase naming prefix."
  default     = "aztfnet"
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,11}$", var.prefix))
    error_message = "Use 3-12 lowercase letters or digits, starting with a letter."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the lab."
  default     = "eastus2"
}

variable "tags" {
  type        = map(string)
  description = "Common tags."
  default = {
    environment = "demo"
    project     = "terraform-azure"
    managed_by  = "terraform"
  }
}