data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

data "azurerm_subnet" "this" {
  for_each = var.vms

  name                 = each.value.subnet_name
  virtual_network_name = "${var.prefix}-${each.value.vnet_key}-vnet"
  resource_group_name  = data.azurerm_resource_group.this.name
}

# Exercise 7: every VM, plus the single SSH key they share.
module "vms" {
  source = "../modules/vms/linux"

  vms = {
    for name, vm in var.vms : name => {
      subnet_id         = data.azurerm_subnet.this[name].id
      size              = vm.size
      install_apache    = vm.role == "web"
      public_ip_enabled = vm.public_ip_enabled
    }
  }

  name_prefix         = var.prefix
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  admin_username      = var.admin_username
  private_key_path    = "${path.root}/${var.prefix}-ssh-key.pem"
  lb_public_ip        = var.lb_public_ip
  tags                = var.tags
}
