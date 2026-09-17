# Deleting this group deletes everything inside it, so keep long-lived resources elsewhere.
resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
  tags     = var.tags
}