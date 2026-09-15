# ROOT STARTER EXAMPLE
# This directory is an independently deployable Terraform root that calls three
# reusable modules. Terraform loads this directory's .tf files, not every example
# or module in the repository. Child modules run only because a source is called.
# Flow: resource group -> VNet and nested subnet -> NSG and subnet association.
# No VM, public IP, NAT gateway, firewall, database or application is created here.
# Keep this root's state separate from Examples/ and Bootstrap/state.

# Purpose: Create the resource group that owns this small starter deployment.
# Creation: Load ./Modules/ResourceGroups and pass the caller's prefix, region and
# tags. AzureRM creates the group using the root provider's external credentials.
# Important: Other modules consume its outputs below, so Terraform can determine
# the creation order without a manual depends_on or a shell deployment sequence.
module "resource_group" {
  source = "./Modules/ResourceGroups"

  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# Purpose: Create a private VNet and one workload subnet using a reusable module.
# Creation: The group outputs order this call after group creation. The Vnet module
# creates its VNet, then calls its own ./subnets child module to create workload.
# The subnet_ids output is a map, so the next module selects its ID by name.
# Important: The subnet CIDR must fit inside the VNet CIDR. Default outbound access
# is disabled by the subnet module; this example provides no Internet egress path.
module "network" {
  source = "./Modules/Vnet"

  name                = "${var.prefix}-vnet"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = [var.vnet_cidr]
  subnets = {
    workload = { address_prefixes = [var.workload_subnet_cidr] }
  }
  tags = var.tags
}

# Purpose: Apply a small, explicit inbound security policy to the workload subnet.
# Creation: Load the nested NSG module, create an HTTPS allow rule for the VNet's
# CIDR plus a final inbound deny, and associate the NSG with the actual subnet ID
# returned above. The references order attachment after the subnet and NSG exist.
# Security: This opens neither public access nor SSH/RDP. It demonstrates network
# policy, not application authentication or a running HTTPS server.
# Important: To use another service, call its ./Modules/... source explicitly and
# pass the inputs its variables.tf requires; do not point source at the entire catalog.
module "workload_nsg" {
  source = "./Modules/Vnet/NSG"

  name                = "${var.prefix}-workload-nsg"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_ids          = { workload = module.network.subnet_ids["workload"] }
  rules = {
    allow_internal_https = {
      priority               = 100
      destination_port_range = "443"
      source_address_prefix  = var.vnet_cidr
    }
    deny_other_inbound = {
      priority               = 4096
      access                 = "Deny"
      protocol               = "*"
      destination_port_range = "*"
      source_address_prefix  = "*"
    }
  }
  tags = var.tags
}