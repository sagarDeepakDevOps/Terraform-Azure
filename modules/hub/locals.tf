locals {
  # Subnets Azure services own; they cannot hold VMs, and the firewall ones reject an NSG or route table.
  reserved_subnets = ["AzureFirewallSubnet", "AzureFirewallManagementSubnet", "AzureBastionSubnet", "GatewaySubnet"]

  vm_subnets     = { for key, subnet in var.subnets : key => subnet if subnet.nsg_rules != null }
  routed_subnets = { for key, subnet in var.subnets : key => subnet if subnet.route_via_firewall }
}
