variable "prefix" {
  type        = string
  description = "Short lowercase naming prefix."
  default     = "aztfai"
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,7}$", var.prefix))
    error_message = "Use 3-8 lowercase letters/digits, starting with a letter."
  }
}

variable "location" {
  type        = string
  description = "Region supporting the selected AI services."
  default     = "eastus2"
}

variable "enable_openai" {
  type        = bool
  description = "Create an Azure OpenAI account, subject to subscription availability and quota."
  default     = false
}

variable "openai_deployments" {
  type = map(object({
    model_name    = string
    model_version = string
    sku_name      = optional(string, "GlobalStandard")
    capacity      = optional(number, 1)
  }))
  description = "Explicitly chosen currently available model versions. Empty means no inference deployment."
  default     = {}
  validation {
    condition     = var.enable_openai || length(var.openai_deployments) == 0
    error_message = "Enable OpenAI before configuring model deployments."
  }
}

variable "enable_machine_learning" {
  type        = bool
  description = "Create a private ML workspace and dependencies, without paid training/inference compute."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Common resource tags."
  default     = { environment = "demo", project = "terraform-azure", managed_by = "terraform" }
}