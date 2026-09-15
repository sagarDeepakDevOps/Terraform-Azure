terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

resource "azurerm_security_center_subscription_pricing" "this" {
  for_each      = var.plans
  resource_type = each.key
  tier          = "Standard"
  subplan       = each.value
}