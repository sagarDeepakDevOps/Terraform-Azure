# Purpose: Create the Azure resource group that owns a set of related lab resources.
# Creation: AzureRM uses the root provider's subscription and credentials to create
# the named group, assign its metadata location, and apply the supplied tags.
# Other modules use this resource's outputs, which orders their creation after it.
# Important: A group's location stores its metadata; child resources choose their
# own regions. Deleting the group can delete its contents, so keep shared backend
# infrastructure separate from short-lived workloads and review deletion plans.
resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
  tags     = var.tags
}