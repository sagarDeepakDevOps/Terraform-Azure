terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Reserve the public entry address of the managed Bastion service.
# Creation: AzureRM creates a static Standard public IP in the same region/group;
# the Bastion host consumes this resource's ID in its IP configuration.
# Important: This address belongs to Bastion, not to a VM NIC. Workload VMs can
# remain private while administrators connect through the managed service.
resource "azurerm_public_ip" "this" {
  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Purpose: Provide managed SSH/RDP access to private VMs without public VM addresses.
# Creation: Azure provisions Standard Bastion in the caller's AzureBastionSubnet
# and attaches the public IP above. Standard enables the configured native-client
# tunneling and IP-based connection capabilities.
# Important: The reserved subnet must be /26 or larger and meet Bastion's network
# requirements. Target NSGs must allow SSH/RDP from it, and the operator still needs
# Azure and guest-login permissions. This creates no VM or credentials and incurs
# recurring charges even when no administrator session is active.
resource "azurerm_bastion_host" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  tunneling_enabled   = true
  ip_connect_enabled  = true
  tags                = var.tags

  ip_configuration {
    name                 = "primary"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.this.id
  }
}