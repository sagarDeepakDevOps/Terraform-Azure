mock_provider "azurerm" {}

run "network_contract" {
  command = plan

  assert {
    condition     = output.resource_group_name == "aztfnet-rg"
    error_message = "Resource group naming must flow through the reusable module."
  }

  assert {
    condition     = length(output.hub_address_space) == 1 && contains(output.hub_address_space, "10.10.0.0/16")
    error_message = "The hub must preserve its requested address space."
  }

  assert {
    condition     = contains(keys(output.hub_subnet_ids), "shared")
    error_message = "The nested subnet module must expose IDs by subnet name."
  }
}

run "subnet_egress_defaults" {
  command = plan

  module {
    source = "../../Modules/Vnet/subnets"
  }

  variables {
    resource_group_name  = "test-rg"
    virtual_network_name = "test-vnet"
    subnets = {
      shared = { address_prefixes = ["10.10.1.0/24"] }
    }
  }

  assert {
    condition     = azurerm_subnet.this["shared"].default_outbound_access_enabled == false
    error_message = "Subnets must not depend on implicit Internet egress."
  }
}