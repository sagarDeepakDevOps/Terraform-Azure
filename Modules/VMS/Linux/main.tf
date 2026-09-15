terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Give the Linux VM a private network interface in the workload subnet.
# Creation: Azure creates a NIC with an IP configuration named primary and allocates
# an available private address from subnet_id. The VM below references this NIC ID,
# which makes Terraform create the NIC before attaching it to the virtual machine.
# Security: No public_ip_address_id is configured. Connectivity depends on subnet
# NSGs/routes and an explicit egress or administration path supplied by the caller.
resource "azurerm_network_interface" "this" {
  name                = "${var.name}-nic"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# Purpose: Provision an Ubuntu 22.04 Gen2 workload VM with private networking.
# Creation: Azure uses the requested size, the NIC above, a Standard SSD managed
# OS disk and the selected marketplace image to build the VM. The public SSH key
# is installed for admin_username; password authentication is disabled.
# Startup: custom_data must already be base64-encoded. Azure passes it to the
# guest's cloud-init; Terraform does not run those guest commands itself. If they
# install packages, wait for the caller's NAT/NSG setup and verify guest completion.
# Security: Secure Boot, vTPM, a system-assigned identity and managed boot diagnostics
# are enabled. The identity has no workload data rights until separately granted.
# Important: Confirm image/size compatibility and quota. The latest image selector
# is a demo convenience, not an immutable production pin. VM/disks are billable,
# and VM creation alone does not guarantee that the application is serving traffic.
resource "azurerm_linux_virtual_machine" "this" {
  name                            = var.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.this.id]
  custom_data                     = var.custom_data
  secure_boot_enabled             = true
  vtpm_enabled                    = true
  tags                            = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {}
}