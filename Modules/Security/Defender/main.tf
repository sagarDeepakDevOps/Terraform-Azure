terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Manage paid Microsoft Defender for Cloud plans for the provider's subscription.
# Creation: for_each sets Standard pricing for every selected resource-type key and
# its requested subplan. This API operates at SUBSCRIPTION scope, even when the
# calling example otherwise creates only a small demo resource group.
# Important: Obtain subscription-owner approval and inspect/import existing settings
# before adopting them into this state. Enabling these plans can charge for resources
# outside the lab. Disabling the module or destroying this setting may change paid
# security coverage; do not treat it as routine disposable-resource cleanup.
# The resource configures plan enrollment, not proof that every workload is protected.
resource "azurerm_security_center_subscription_pricing" "this" {
  for_each      = var.plans
  resource_type = each.key
  tier          = "Standard"
  subplan       = each.value
}