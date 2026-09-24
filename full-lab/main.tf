# The whole lab as one root: modules are wired directly, so one apply builds everything in order.

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

# exercise3. Uses the VNet module's output name so Terraform sees the dependency.
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

# Owned by the root so the VMs and the load balancer can both use it without a module cycle.
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

  # Azure rejects concurrent subnet writes, and cloud-init needs the NAT gateway at first boot.
  depends_on = [module.nsgs, module.nat_gateways]
}

# exercise8. The backend pool comes from web-role VMs, so the jump host can never join it.
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
