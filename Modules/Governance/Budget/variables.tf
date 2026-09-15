variable "name" {
  type        = string
  description = "Monthly budget name. Budgets notify; they do not stop spending or shut down resources."
}

variable "resource_group_id" {
  type        = string
  description = "Resource group billing scope. Billing permissions and a supported subscription offer are required."
}

variable "monthly_amount" {
  type        = number
  description = "Monthly amount in the billing account currency, not necessarily USD."
  default     = 100
}

variable "start_date" {
  type        = string
  description = "First day of the current month or an allowed future month in UTC, e.g. YYYY-MM-01T00:00:00Z."
  validation {
    condition     = can(regex("^[0-9]{4}-[0-9]{2}-01T00:00:00Z$", var.start_date))
    error_message = "Use an explicit first-of-month UTC timestamp."
  }
}

variable "contact_emails" {
  type        = list(string)
  description = "Budget notification recipients."
}