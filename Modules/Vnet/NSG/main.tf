terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Define stateful network allow/deny rules for workload traffic.
# Creation: AzureRM creates one NSG in the supplied group/region. The dynamic
# security_rule block expands var.rules into named rules, using each definition's
# direction, priority, protocol, destination port and address prefixes.
# Behavior: Lower priority numbers are evaluated first. Azure's default rules still
# exist; an explicit higher-precedence deny can narrow their broad VNet allowances.
# Important: Defining rules alone filters nothing until the NSG is associated below.
# Rules are owned inline here; do not manage the same rules with separate resources.
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

# Purpose: Apply this NSG to the caller's selected workload subnets.
# Creation: for_each creates one association per stable subnet-map key. Each
# association references both the target subnet ID and the newly created NSG ID,
# so Terraform waits for those resources before Azure attaches the security group.
# Important: A subnet can have only one NSG association. Do not include reserved
# gateway/firewall subnets that prohibit this configuration; service-specific
# subnets may need additional mandatory rules rather than generic workload rules.
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each                  = var.subnet_ids
  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.this.id
}