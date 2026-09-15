terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Place the Windows VM on a private workload subnet without a public NIC IP.
# Creation: Azure allocates a dynamic private address in subnet_id and records it
# on the NIC's primary IP configuration. The VM below uses this new interface ID.
# Important: This does not open RDP. An approved private/Bastion path, matching NSG
# rules and Windows login rights are required for administrative access.
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

# Purpose: Provision a Windows Server 2022 Azure Edition VM for the optional demo.
# Creation: Azure combines the marketplace image, requested size, private NIC and
# Standard SSD OS disk. name identifies the Azure resource; computer_name is the
# Windows hostname and must meet Windows naming limits. The supplied local admin
# credentials initialize guest access; no domain join or application is configured.
# Security: Secure Boot/vTPM, system-assigned identity and managed boot diagnostics
# are enabled. The password is sensitive but still stored in Terraform state.
# Important: Verify image/size support, password complexity and quota. Production
# needs credential rotation, patching and an immutable image strategy; choosing
# latest here does not implement those operational controls or an RDP access path.
resource "azurerm_windows_virtual_machine" "this" {
  name                  = var.name
  computer_name         = var.computer_name
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.this.id]
  secure_boot_enabled   = true
  vtpm_enabled          = true
  tags                  = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {}
}