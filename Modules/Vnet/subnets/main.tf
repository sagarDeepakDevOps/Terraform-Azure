# Purpose: Divide an existing VNet into named address ranges with service-specific
# settings, such as delegation for a database or disabled endpoint network policies.
# Creation: for_each creates one Azure subnet per map entry. each.key is its Azure
# name; each.value supplies CIDRs, service endpoints and optional delegation.
# The dynamic block emits no delegation when null, or one service delegation when
# configured. Delegation authorizes that Azure service to manage its subnet use.
# Security: Implicit outbound Internet access is disabled. Workloads that need
# egress must have an explicit design such as NAT, Firewall or supported LB egress.
# Important: Subnet ranges must fit the VNet and not overlap. Respect reserved names
# and sizes for gateway/appliance subnets. Service endpoints are not private
# endpoints; private endpoint traffic filtering also depends on its policy setting.
resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                              = each.key
  resource_group_name               = var.resource_group_name
  virtual_network_name              = var.virtual_network_name
  address_prefixes                  = each.value.address_prefixes
  service_endpoints                 = each.value.service_endpoints
  private_endpoint_network_policies = each.value.private_endpoint_network_policies
  default_outbound_access_enabled   = false

  dynamic "delegation" {
    for_each = each.value.delegation == null ? [] : [each.value.delegation]
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }
}