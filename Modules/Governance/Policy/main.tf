terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Apply Azure's built-in Allowed locations policy to one resource group.
# Creation: Reference the existing built-in policy definition by its stable ID,
# scope the assignment to resource_group_id and JSON-encode the allowed region list
# in the parameter shape expected by Azure Policy. No custom definition is created.
# Behavior: enforce=false uses DoNotEnforce, allowing compliance evaluation without
# enforcing the policy's Deny behavior; true can block noncompliant future operations.
# Important: This is not subscription-wide placement control, does not relocate
# existing resources, and requires policy-assignment permissions at the target scope.
resource "azurerm_resource_group_policy_assignment" "this" {
  name                 = "allowed-locations"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  display_name         = "Allowed locations for this demonstration resource group"
  enforce              = var.enforce
  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_locations }
  })

  non_compliance_message {
    content = "Deploy regional resources only in the approved locations."
  }
}