locals {
  # Each VM keeps its own key file in the project root; .gitignore already excludes *.pem.
  private_key_path = "${path.root}/${var.name}-ssh-key.pem"

  public_ip_address = var.public_ip_enabled ? azurerm_public_ip.this[0].ip_address : ""

  # The load balancer virtual host answers to its DNS label, or to the bare frontend IP when there is none.
  lb_server_name = coalesce(var.lb_fqdn, var.lb_public_ip, "load-balancer.invalid")

  direct_html = templatefile("${path.module}/templates/index.html.tftpl", {
    vm_name     = var.name
    entry_label = "Direct to the VM public IP"
    entry_ip    = local.public_ip_address
    private_ip  = azurerm_network_interface.this.private_ip_address
  })

  via_lb_html = templatefile("${path.module}/templates/index.html.tftpl", {
    vm_name     = var.name
    entry_label = "Through the public load balancer (${local.lb_server_name})"
    entry_ip    = coalesce(var.lb_public_ip, "unknown")
    private_ip  = azurerm_network_interface.this.private_ip_address
  })

  apache_conf = templatefile("${path.module}/templates/apache.conf.tftpl", {
    vm_server_name = coalesce(local.public_ip_address, var.name)
    lb_server_name = local.lb_server_name
  })

  cloud_init = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    apache_conf = local.apache_conf
    direct_html = local.direct_html
    via_lb_html = local.via_lb_html
  })
}
