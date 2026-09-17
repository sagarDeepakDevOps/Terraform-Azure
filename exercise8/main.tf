data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

# Finds the NICs exercise7 created, so the backend pool needs only their VM names.
data "azurerm_network_interface" "this" {
  for_each = toset(var.backend_vm_names)

  name                = "${var.prefix}-${each.value}-nic"
  resource_group_name = data.azurerm_resource_group.this.name
}

# Exercise 8: the public entry point that spreads traffic across the web VMs.
module "load_balancer" {
  source = "../modules/loadbalancers"

  name                = "${var.prefix}-lb"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  domain_name_label   = var.lb_domain_name_label
  frontend_port       = var.http_port
  backend_port        = var.http_port
  backend_nic_ids     = { for name, nic in data.azurerm_network_interface.this : name => nic.id }
  tags                = var.tags
}
