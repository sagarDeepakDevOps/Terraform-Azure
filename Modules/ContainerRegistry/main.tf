terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create Azure Container Registry to hold versioned container images/artifacts.
# Creation: AzureRM provisions the globally named registry at the selected SKU;
# callers receive its ARM ID for role grants and login_server for image references.
# Security: Shared administrator credentials and anonymous pulls are disabled.
# Applications authenticate using scoped identities such as the AcrPull grants in
# the container examples; image-publishing identities need their own push permissions.
# Important: Basic uses an authenticated public endpoint. Private networking requires
# a supporting SKU such as Premium plus registry endpoints/DNS. This resource builds
# or uploads no images, and the registry's capacity remains billable when idle.
resource "azurerm_container_registry" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = false
  anonymous_pull_enabled        = false
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags
}