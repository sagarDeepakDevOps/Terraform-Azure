module "vnet" {
  source = "../networking/vnet"

  name                = "${var.name_prefix}-hub-vnet"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  subnets             = var.subnets
  tags                = var.tags
}

# Every packet leaving a spoke passes through here: to the Internet, to another spoke, or back to a client.
module "firewall" {
  source = "../networking/firewall"

  name                 = "${var.name_prefix}-hub-fw"
  resource_group_name  = var.resource_group_name
  location             = var.location
  sku_tier             = var.firewall_sku_tier
  subnet_id            = module.vnet.subnet_ids["AzureFirewallSubnet"]
  management_subnet_id = try(module.vnet.subnet_ids["AzureFirewallManagementSubnet"], null)
  dnat_rules           = var.firewall_dnat_rules
  network_rules        = var.firewall_network_rules
  application_rules    = var.firewall_application_rules
  tags                 = var.tags
}

# SSH to any spoke VM without giving it a public IP.
module "bastion" {
  source = "../networking/bastion"

  name                = "${var.name_prefix}-hub-bastion"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.bastion_sku
  subnet_id           = module.vnet.subnet_ids["AzureBastionSubnet"]
  tags                = var.tags
}
