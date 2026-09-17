terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Rules expand from var.rules and filter nothing until the association below attaches them to a subnet.
resource "azurerm_network_security_group" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  dynamic "security_rule" {
    for_each = var.rules
    content {
      name                       = security_rule.key
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = "*"
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

# One association per subnet key; a subnet can carry only one NSG, and reserved gateway subnets accept none.
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each                  = var.subnet_ids
  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.this.id
}