terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Reduce accidental management-plane deletion at the selected Azure scope.
# Creation: AzureRM adds a CanNotDelete lock to the supplied resource or resource-group
# ARM ID. If the ID comes from a module output, Terraform waits for that target.
# A group-level lock is inherited by resources beneath that group.
# Important: This is not a ReadOnly lock, data backup or Terraform state lease.
# Authorized users/Terraform can remove it, including during a reviewed destroy;
# protecting blobs/database rows and retaining recovery data are separate controls.
resource "azurerm_management_lock" "this" {
  name       = var.name
  scope      = var.scope
  lock_level = "CanNotDelete"
  notes      = "Remove deliberately before deleting protected resources. This is not a data-plane backup."
}