# Two peered VNets, Apache VMs in the workload VNet, and a Standard public load balancer in front.

# Owns every resource in the lab; deleting it is the cleanup path.
module "resource_group" {
  source = "./Modules/ResourceGroups"

  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# One VNet per map key, each looping again over its own subnet map, so subnet count is independent of VNet count.
module "vnets" {
  source   = "./Modules/Networking/vnet"
  for_each = var.vnets

  name                = "${var.prefix}-${each.key}-vnet"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = each.value.address_space
  subnets             = each.value.subnets
  tags                = var.tags
}

# One NSG per VNet, associated with every subnet that VNet created.
module "nsgs" {
  source   = "./Modules/Networking/NSG"
  for_each = var.vnets

  name                = "${var.prefix}-${each.key}-nsg"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_ids          = module.vnets[each.key].subnet_ids
  rules               = local.nsg_rules
  tags                = var.tags
}

# Both directions of each named peering; the load balancer does not use it, but private traffic can.
module "peerings" {
  source   = "./Modules/Networking/Peering"
  for_each = var.vnet_peerings

  first = {
    name                = module.vnets[each.value.first].name
    id                  = module.vnets[each.value.first].id
    resource_group_name = module.resource_group.name
  }
  second = {
    name                = module.vnets[each.value.second].name
    id                  = module.vnets[each.value.second].id
    resource_group_name = module.resource_group.name
  }
}

# One VM, NIC, public IP and SSH key pair per map key; editing the page changes custom_data, which replaces the VM.
module "vms" {
  source   = "./Modules/VMS/Linux"
  for_each = var.vms

  name                = "${var.prefix}-${each.key}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = module.vnets[each.value.vnet_key].subnet_ids[each.value.subnet_key]
  size                = each.value.size
  admin_username      = var.admin_username
  domain_name_label   = each.value.domain_name_label
  lb_fqdn             = module.load_balancer.public_ip_fqdn
  lb_public_ip        = module.load_balancer.public_ip_address
  tags                = var.tags
}

# Keying the NIC map by VM name keeps the for_each keys known at plan time; no cycle, since Terraform tracks each variable and output separately.
module "load_balancer" {
  source = "./Modules/LoadBalancers"

  name                = "${var.prefix}-lb"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  domain_name_label   = var.lb_domain_name_label
  frontend_port       = var.http_port
  backend_port        = var.http_port
  backend_nic_ids     = { for name, vm in module.vms : name => vm.network_interface_id }
  tags                = var.tags
}
