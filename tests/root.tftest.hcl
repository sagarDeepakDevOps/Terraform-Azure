# Replace AzureRM with a schema-compatible mock so these plans never authenticate
# to Azure or create real resources. A live deployment still needs a separate review.
mock_provider "azurerm" {}

# Verify that the three root calls compose the group, nested subnet and NSG binding.
run "default_module_composition" {
  command = plan

  assert {
    condition     = output.resource_group_name == "aztfroot-rg" && output.vnet_name == "aztfroot-vnet"
    error_message = "The root naming prefix must flow through the resource group and VNet modules."
  }

  assert {
    condition     = length(output.vnet_address_space) == 1 && contains(output.vnet_address_space, "10.120.0.0/16")
    error_message = "The VNet module must preserve the starter address space."
  }

  assert {
    condition     = length(output.subnet_ids) == 1 && contains(keys(output.subnet_ids), "workload")
    error_message = "The Vnet module must create and export the named workload subnet."
  }

  assert {
    condition     = length(module.workload_nsg.association_ids) == 1 && contains(keys(module.workload_nsg.association_ids), "workload")
    error_message = "The NSG module must associate its rules with the workload subnet."
  }
}

# Demonstrate that callers can reuse these same modules with different root inputs.
run "custom_module_inputs" {
  command = plan

  variables {
    prefix               = "clientdemo"
    location             = "centralindia"
    vnet_cidr            = "10.121.0.0/16"
    workload_subnet_cidr = "10.121.1.0/24"
  }

  assert {
    condition     = output.resource_group_name == "clientdemo-rg" && output.vnet_name == "clientdemo-vnet"
    error_message = "Custom root inputs must rename both modules without editing their implementation."
  }

  assert {
    condition     = contains(output.vnet_address_space, "10.121.0.0/16") && module.resource_group.location == "centralindia"
    error_message = "Custom address space and region must be passed to the child modules."
  }
}