locals {
  # Shared private key for every VM; .gitignore already excludes *.pem.
  private_key_path = "${path.root}/${var.prefix}-ssh-key.pem"

  # Flattens every VNet's subnets into one map, so NSGs and NAT gateways are per subnet rather than per network.
  subnets = merge([
    for vnet_key, vnet in var.vnets : {
      for subnet_key, subnet in vnet.subnets :
      "${vnet_key}-${subnet_key}" => {
        subnet_key          = subnet_key
        subnet_id           = module.vnets[vnet_key].subnet_ids[subnet_key]
        nsg_rules           = subnet.nsg_rules
        nat_gateway_enabled = subnet.nat_gateway_enabled
      }
    }
  ]...)

  nat_subnets = { for key, subnet in local.subnets : key => subnet if subnet.nat_gateway_enabled }

  # Resolves each VM's subnet and turns its role into the flags the VM module takes.
  vms = {
    for name, vm in var.vms : name => {
      subnet_id         = module.vnets[vm.vnet_key].subnet_ids[vm.subnet_key]
      size              = vm.size
      install_apache    = vm.role == "web"
      public_ip_enabled = vm.public_ip_enabled
      domain_name_label = vm.domain_name_label
    }
  }
}
