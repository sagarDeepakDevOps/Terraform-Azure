locals {
  cloud_init = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    vm_name = var.computer_name
    vnet    = var.vnet_name
  })

  custom_data = var.install_apache ? base64encode(local.cloud_init) : null
}
