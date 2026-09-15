terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Reserve a stable public VPN peer address for the Azure gateway.
# Creation: AzureRM requests a Standard static IP spanning zones 1, 2 and 3 in
# the chosen region, and the virtual network gateway references its ID below.
# Important: Confirm regional zone/SKU availability. The resulting address is
# provided to the remote VPN operator; creating it alone does not establish a tunnel.
resource "azurerm_public_ip" "this" {
  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

# Purpose: Create Azure's route-based VPN gateway for hybrid network connectivity.
# Creation: Azure deploys VpnGw1AZ into the caller's reserved GatewaySubnet, using
# the public IP above and a dynamically assigned private address. This SKU uses
# Generation1; selecting Generation2 with VpnGw1AZ would be an invalid pairing.
# Behavior: BGP and active-active are disabled in this example; on-premises ranges
# are supplied through the local-network-gateway object instead of learned by BGP.
# Important: Use a /27 or larger GatewaySubnet without an NSG. Gateway creation
# can be slow and has recurring costs; the connection and remote VPN configuration
# below/elsewhere are still required for a working site-to-site path.
resource "azurerm_virtual_network_gateway" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1AZ"
  generation          = "Generation1"
  active_active       = false
  bgp_enabled         = false
  tags                = var.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

# Purpose: Describe the remote VPN device and the address ranges behind it to Azure.
# Creation: count creates this object only when on_premises is supplied; its public
# peer IP and routed CIDRs come from that object. It is an Azure configuration
# record in this resource group, not a gateway installed on the customer's premises.
# Important: Supply a reachable real peer and non-overlapping networks. The remote
# firewall/router, return routes and tunnel policies must be configured separately.
resource "azurerm_local_network_gateway" "this" {
  count               = var.on_premises == null ? 0 : 1
  name                = "${var.name}-onprem"
  resource_group_name = var.resource_group_name
  location            = var.location
  gateway_address     = var.on_premises.gateway_address
  address_space       = var.on_premises.address_space
  tags                = var.tags
}

# Purpose: Join the Azure and remote gateway definitions into an IKEv2 IPsec tunnel.
# Creation: When on_premises is present, reference both gateway IDs and submit the
# supplied shared key. Those IDs order the connection after gateway provisioning.
# Important: The remote peer must use matching authentication and compatible IKE/
# IPsec settings. A created connection object is not proof that tunnel negotiation
# or end-to-end traffic works. The pre-shared key is sensitive but remains in
# Terraform state, so never expose state or connection outputs in presentation logs.
resource "azurerm_virtual_network_gateway_connection" "this" {
  count                      = var.on_premises == null ? 0 : 1
  name                       = "${var.name}-s2s"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this.id
  local_network_gateway_id   = azurerm_local_network_gateway.this[0].id
  shared_key                 = var.shared_key
  connection_protocol        = "IKEv2"
  tags                       = var.tags
}