module "resource_group" {
  source = "./modules/resource-group"

  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# One key pair shared by every VM.
module "ssh_key" {
  source = "./modules/security/ssh-key"

  private_key_path = "${path.root}/${var.prefix}-ssh-key.pem"
}

module "hub" {
  source = "./modules/hub"

  name_prefix                = var.prefix
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  address_space              = var.hub.address_space
  subnets                    = var.hub.subnets
  firewall_sku_tier          = var.hub.firewall_sku_tier
  bastion_sku                = var.hub.bastion_sku
  firewall_dnat_rules        = local.firewall_dnat_rules
  firewall_network_rules     = local.firewall_network_rules
  firewall_application_rules = local.firewall_application_rules
  tags                       = var.tags
}

module "spokes" {
  source   = "./modules/spoke"
  for_each = var.spokes

  name                = each.key
  name_prefix         = var.prefix
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = each.value.address_space
  subnets             = each.value.subnets
  hub_vnet            = module.hub.vnet
  firewall_private_ip = module.hub.firewall_private_ip
  tags                = var.tags
}

module "vms" {
  source   = "./modules/compute/linux-vm"
  for_each = var.vms

  name                = "${var.prefix}-${each.key}"
  computer_name       = each.key
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = local.subnet_ids[each.value.vnet_key][each.value.subnet_key]
  private_ip_address  = each.value.private_ip_address
  size                = each.value.size
  install_apache      = each.value.install_apache
  vnet_name           = each.value.vnet_key
  admin_username      = var.admin_username
  ssh_public_key      = module.ssh_key.public_key_openssh
  tags                = var.tags
}
