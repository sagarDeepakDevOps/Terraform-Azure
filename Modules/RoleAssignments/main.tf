terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Grant named Azure roles to existing users, groups or workload identities.
# Creation: for_each creates one assignment per stable input key, combining the
# target ARM scope, built-in role name, principal object ID and principal type.
# References to created scopes/identities order grants after those resources exist.
# Security: The caller needs roleAssignments/write at each scope; ordinary resource
# Contributor does not automatically grant that right. Scope permissions narrowly.
# Important: principal_id is an Entra object ID, not an application client ID.
# Grants can take time to propagate, do not provide network access, and Azure
# management roles are not interchangeable with each service's data-plane roles.
resource "azurerm_role_assignment" "this" {
  for_each             = var.assignments
  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
  principal_type       = each.value.principal_type
}