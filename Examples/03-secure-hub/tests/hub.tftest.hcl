mock_provider "azurerm" {}

run "vpn_sku_generation" {
  command = plan

  module {
    source = "../../Modules/Vnet/VPNGateway"
  }

  variables {
    name                = "test-vpn"
    resource_group_name = "test-rg"
    location            = "eastus2"
    subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/GatewaySubnet"
  }

  assert {
    condition     = azurerm_virtual_network_gateway.this.sku == "VpnGw1AZ" && azurerm_virtual_network_gateway.this.generation == "Generation1"
    error_message = "VpnGw1AZ supports Generation1, not Generation2."
  }
}

run "firewall_hub" {
  command = plan

  assert {
    condition     = contains(keys(output.hub_subnets), "AzureFirewallSubnet")
    error_message = "Firewall must have its correctly named dedicated subnet."
  }

  assert {
    condition     = !output.optional_components.bastion && !output.optional_components.vpn
    error_message = "Bastion and VPN must be opt-in."
  }
}

run "hybrid_hub" {
  command = plan

  variables {
    enable_bastion = true
    enable_vpn     = true
    on_premises = {
      gateway_address = "198.51.100.10"
      address_space   = ["172.20.0.0/16"]
    }
    vpn_shared_key = "MockOnly-NotARealCredential-123!"
  }

  assert {
    condition     = output.optional_components.bastion && output.optional_components.vpn
    error_message = "Optional hybrid network resources must plan together."
  }
}