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

# One NSG per subnet, carrying only that subnet's own rules.
module "nsgs" {
  source   = "./Modules/Networking/NSG"
  for_each = local.subnets

  name                = "${var.prefix}-${each.key}-nsg"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_ids          = { (each.value.subnet_key) = each.value.subnet_id }
  rules               = each.value.nsg_rules
  tags                = var.tags
}

# Outbound Internet for subnets whose VMs have no public IP, so cloud-init can reach the apt mirrors.
module "nat_gateways" {
  source   = "./Modules/Networking/NATGateway"
  for_each = local.nat_subnets

  name                = "${var.prefix}-${each.key}-nat"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_ids          = { (each.value.subnet_key) = each.value.subnet_id }
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

# Called once; it loops over the VM map internally and owns the single SSH key they all share.
module "vms" {
  source = "./Modules/VMS/Linux"

  vms                 = local.vms
  name_prefix         = var.prefix
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  admin_username      = var.admin_username
  private_key_path    = local.private_key_path
  lb_fqdn             = module.load_balancer.public_ip_fqdn
  lb_public_ip        = module.load_balancer.public_ip_address
  tags                = var.tags

  # Private VMs have no egress until their subnet's NAT gateway is attached, and
  # cloud-init would fail to reach the apt mirrors. No value links these, so say it.
  depends_on = [module.nat_gateways]
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
  backend_nic_ids     = { for name, id in module.vms.network_interface_ids : name => id if var.vms[name].role == "web" }
  tags                = var.tags
}
