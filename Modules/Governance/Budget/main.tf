terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Notify owners about the selected resource group's monthly Azure spending.
# Creation: AzureRM creates a monthly budget for monthly_amount in the billing
# account's currency, starting on the explicit first-of-month UTC date. Notifications
# target contact_emails at 80% actual spend and 100% forecasted spend.
# Important: The subscription offer and caller must support budget/billing access.
# Cost data and notifications can lag behind usage. A budget is not a hard limit,
# does not shut down services and does not prevent the next paid resource creation.
# This budget covers only its resource-group scope, not all example deployments.
resource "azurerm_consumption_budget_resource_group" "this" {
  name              = var.name
  resource_group_id = var.resource_group_id
  amount            = var.monthly_amount
  time_grain        = "Monthly"

  time_period {
    start_date = var.start_date
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = var.contact_emails
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Forecasted"
    contact_emails = var.contact_emails
  }
}