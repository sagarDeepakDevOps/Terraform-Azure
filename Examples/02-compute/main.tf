module "resource_group" {
  source   = "../../Modules/ResourceGroups"
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

module "network" {
  source              = "../../Modules/Vnet"
  name                = "${var.prefix}-vnet"
  resource_group_name = module.resource_group.name
  location            = var.location
  address_space       = ["10.30.0.0/16"]
  subnets = {
    workload = { address_prefixes = ["10.30.1.0/24"] }
  }
  tags = var.tags
}

module "nsg" {
  source              = "../../Modules/Vnet/NSG"
  name                = "${var.prefix}-nsg"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_ids          = { workload = module.network.subnet_ids["workload"] }
  rules = {
    allow_http = {
      priority = 100, destination_port_range = "80", source_address_prefix = "Internet"
    }
    allow_probe = {
      priority = 110, destination_port_range = "80", source_address_prefix = "AzureLoadBalancer"
    }
    deny_other_inbound = {
      priority = 4096, access = "Deny", protocol = "*", destination_port_range = "*", source_address_prefix = "*"
    }
  }
  tags = var.tags
}

module "nat" {
  source              = "../../Modules/Vnet/NATGateway"
  name                = "${var.prefix}-nat"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_ids          = { workload = module.network.subnet_ids["workload"] }
  tags                = var.tags
}

module "linux" {
  source   = "../../Modules/VMS/Linux"
  for_each = toset(["web01", "web02"])

  name                = "${var.prefix}-${each.key}"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_id           = module.network.subnet_ids["workload"]
  ssh_public_key      = var.ssh_public_key
  custom_data         = filebase64("${path.module}/cloud-init.yaml")
  tags                = var.tags

  depends_on = [module.nat, module.nsg]
}

module "load_balancer" {
  source              = "../../Modules/LoadBalancers"
  name                = "${var.prefix}-lb"
  resource_group_name = module.resource_group.name
  location            = var.location
  backend_nic_ids     = { for name, vm in module.linux : name => vm.network_interface_id }
  tags                = var.tags
}

module "windows" {
  source              = "../../Modules/VMS/Windows"
  count               = var.enable_windows ? 1 : 0
  name                = "${var.prefix}-windows"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_id           = module.network.subnet_ids["workload"]
  admin_password      = var.windows_admin_password
  tags                = var.tags

  depends_on = [module.nat, module.nsg]
}

module "scale_set" {
  source              = "../../Modules/VMScaleSets"
  count               = var.enable_scale_set ? 1 : 0
  name                = "${var.prefix}-vmss"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_id           = module.network.subnet_ids["workload"]
  backend_pool_id     = module.load_balancer.backend_pool_id
  ssh_public_key      = var.ssh_public_key
  custom_data         = filebase64("${path.module}/cloud-init.yaml")
  tags                = var.tags

  depends_on = [module.nat, module.nsg]
}

module "backup" {
  source              = "../../Modules/Backup"
  count               = var.enable_backup ? 1 : 0
  name                = "${var.prefix}-vault"
  resource_group_name = module.resource_group.name
  location            = var.location
  virtual_machine_ids = { for name, vm in module.linux : name => vm.id }
  tags                = var.tags
}