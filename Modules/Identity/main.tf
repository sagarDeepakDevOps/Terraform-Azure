terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create a reusable Azure-managed workload identity without a stored secret.
# Creation: AzureRM creates a user-assigned identity in the requested group/region;
# Azure also provisions its Entra service principal. Outputs expose three distinct
# values: ARM id for attaching the identity, principal_id for RBAC grants, and
# client_id for selecting this identity in application authentication.
# Important: Creation alone neither attaches the identity to a workload nor grants
# access to data. Callers must do both explicitly. Its lifetime is independent of
# an individual VM/app, unlike an identity assigned automatically to that resource.
resource "azurerm_user_assigned_identity" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}