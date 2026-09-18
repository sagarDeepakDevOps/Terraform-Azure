# The whole lab in one configuration.
#
# Exercises 1 to 8 build this same network as eight separate roots, each with its
# own state, each finding the one before it with a data source. Here the modules
# are wired to each other directly, so one apply builds everything and Terraform
# works out the order itself.

module "resource_group" {
  source = "../modules/resourcegroups"

  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# exercise2
module "vnets" {
  source   = "../modules/networking/vnet"
  for_each = var.vnets

  name                = "${var.prefix}-${each.key}-vnet"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = each.value.address_space
  tags                = var.tags
}

# exercise3. The VNet name comes from the module output rather than being rebuilt
# from the prefix, which is what makes the dependency real instead of implied.
module "subnets" {
  source   = "../modules/networking/subnets"
  for_each = var.vnet_subnets

  resource_group_name  = module.resource_group.name
  virtual_network_name = module.vnets[each.key].name
  subnets              = each.value
}

# exercise4
module "nsgs" {
  source   = "../modules/networking/nsg"
  for_each = var.nsgs

  name                = "${var.prefix}-${each.key}-nsg"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_ids          = { (each.value.subnet_name) = module.subnets[each.value.vnet_key].ids[each.value.subnet_name] }
  rules               = each.value.rules
  tags                = var.tags
}

# exercise5
module "peerings" {
  source   = "../modules/networking/peering"
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

# exercise6
module "nat_gateways" {
  source   = "../modules/networking/natgateway"
  for_each = var.nat_gateways

  name                = "${var.prefix}-${each.key}-nat"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_ids          = { (each.value.subnet_name) = module.subnets[each.value.vnet_key].ids[each.value.subnet_name] }
  tags                = var.tags
}

# The load balancer's frontend address, created here rather than inside the load
# balancer module, and this is the whole reason a single root is worth building.
#
# The VMs want the address because it is baked into the page cloud-init writes.
# The load balancer wants the VM NICs for its backend pool. Module to module that
# is a cycle and Terraform refuses it. Hoisting the one shared resource up into
# the root breaks it: the address depends on neither, and both depend on it.
#
# Separate roots dodge the same problem by applying exercise7, then exercise8,
# then exercise7 again. Here it is one apply.
resource "azurerm_public_ip" "lb" {
  name                = "${var.prefix}-lb-pip"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.lb_domain_name_label
  tags                = var.tags
}

# exercise7
module "vms" {
  source = "../modules/vms/linux"

  vms = {
    for name, vm in var.vms : name => {
      subnet_id         = module.subnets[vm.vnet_key].ids[vm.subnet_name]
      size              = vm.size
      install_apache    = vm.role == "web"
      public_ip_enabled = vm.public_ip_enabled
    }
  }

  name_prefix         = var.prefix
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  admin_username      = var.admin_username
  private_key_path    = "${path.root}/${var.prefix}-ssh-key.pem"
  lb_public_ip        = azurerm_public_ip.lb.ip_address
  lb_fqdn             = azurerm_public_ip.lb.fqdn
  tags                = var.tags

  # Nothing here reads the NSG or the NAT gateway, so Terraform is free to build
  # a NIC in a subnet while those are still attaching to it. Azure rejects
  # concurrent writes to one subnet, and the web VM needs the NAT gateway in
  # place at first boot or cloud-init cannot reach the Ubuntu archive.
  depends_on = [module.nsgs, module.nat_gateways]
}

# exercise8. The backend pool is derived from the VMs whose role is web, so there
# is no second list to keep in step, and the jump host cannot end up in it.
module "load_balancer" {
  source = "../modules/loadbalancers"

  name                = "${var.prefix}-lb"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  frontend_port       = var.http_port
  backend_port        = var.http_port
  backend_nic_ids     = { for name in local.web_vm_names : name => module.vms.network_interface_ids[name] }

  existing_public_ip = {
    id         = azurerm_public_ip.lb.id
    ip_address = azurerm_public_ip.lb.ip_address
    fqdn       = azurerm_public_ip.lb.fqdn
  }

  tags = var.tags
}
