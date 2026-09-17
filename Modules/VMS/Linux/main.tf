terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0, < 5.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.0, < 3.0.0"
    }
  }
}

# One per VM that asked for one; it exposes the VM and gives cloud-init its outbound path for apt.
resource "azurerm_public_ip" "this" {
  for_each = { for key, vm in var.vms : key => vm if vm.public_ip_enabled }

  name                = "${local.vm_names[each.key]}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = each.value.domain_name_label
  tags                = var.tags
}

# The load balancer pools these interfaces by the IP configuration name primary; renaming it breaks that.
resource "azurerm_network_interface" "this" {
  for_each = var.vms

  name                = "${local.vm_names[each.key]}-nic"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = each.value.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = try(azurerm_public_ip.this[each.key].id, null)
  }
}

# Ubuntu 22.04; VMs with install_apache serve the demo page, and apply returns before cloud-init finishes.
resource "azurerm_linux_virtual_machine" "this" {
  for_each = var.vms

  name                            = local.vm_names[each.key]
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = each.value.size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.this[each.key].id]
  custom_data                     = local.custom_data[each.key]
  secure_boot_enabled             = true
  vtpm_enabled                    = true
  tags                            = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.vms.public_key_openssh
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
