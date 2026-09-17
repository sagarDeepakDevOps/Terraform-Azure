locals {
  vm_names = { for key in keys(var.vms) : key => "${var.name_prefix}-${key}" }

  # try() because the public IP map only holds VMs that asked for one.
  public_ips = { for key in keys(var.vms) : key => try(azurerm_public_ip.this[key].ip_address, "") }

  # The load balancer virtual host answers to its DNS label, or to the bare frontend IP when there is none.
  lb_server_name = coalesce(var.lb_fqdn, var.lb_public_ip, "load-balancer.invalid")

  # Rendered for every VM so both branches of custom_data below stay valid; only Apache hosts actually use it.
  cloud_init = {
    for key, vm in var.vms : key => templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
      apache_conf = templatefile("${path.module}/templates/apache.conf.tftpl", {
        vm_server_name = coalesce(local.public_ips[key], azurerm_network_interface.this[key].private_ip_address)
        lb_server_name = local.lb_server_name
      })
      direct_html = templatefile("${path.module}/templates/index.html.tftpl", {
        vm_name     = local.vm_names[key]
        entry_label = vm.public_ip_enabled ? "Direct to the VM public IP" : "Direct to the VM private IP"
        entry_ip    = coalesce(local.public_ips[key], azurerm_network_interface.this[key].private_ip_address)
        private_ip  = azurerm_network_interface.this[key].private_ip_address
      })
      via_lb_html = templatefile("${path.module}/templates/index.html.tftpl", {
        vm_name     = local.vm_names[key]
        entry_label = "Through the public load balancer (${local.lb_server_name})"
        entry_ip    = coalesce(var.lb_public_ip, "unknown")
        private_ip  = azurerm_network_interface.this[key].private_ip_address
      })
    })
  }

  custom_data = { for key, vm in var.vms : key => vm.install_apache ? base64encode(local.cloud_init[key]) : null }
}
