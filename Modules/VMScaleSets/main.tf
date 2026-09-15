terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create a repeatable fleet of Ubuntu web instances behind one load balancer.
# Creation: Azure starts with two instances of this VM model, each using the same
# image, SSH key, Standard SSD OS disk and base64 cloud-init input. Instance NICs
# are private and join the supplied subnet and backend_pool_id directly.
# Security: Password login is disabled, Secure Boot/vTPM and managed identity are
# enabled, and boot diagnostics use Azure-managed storage. The caller supplies
# explicit egress and NSG rules; a backend pool does not provide those by itself.
# Lifecycle: Manual upgrade mode requires an explicit instance upgrade process.
# ignore_changes on instances lets Azure Monitor change fleet size without each
# subsequent Terraform apply undoing autoscaling; the model remains managed here.
# Important: This is demo capacity, not a complete multi-zone availability design.
# Scaling and image changes still need health checks, quota and application testing.
resource "azurerm_linux_virtual_machine_scale_set" "this" {
  name                            = var.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  sku                             = var.sku
  instances                       = 2
  admin_username                  = "azureuser"
  disable_password_authentication = true
  custom_data                     = var.custom_data
  upgrade_mode                    = "Manual"
  secure_boot_enabled             = true
  vtpm_enabled                    = true
  tags                            = var.tags

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  network_interface {
    name    = "primary"
    primary = true
    ip_configuration {
      name                                   = "primary"
      primary                                = true
      subnet_id                              = var.subnet_id
      load_balancer_backend_address_pool_ids = [var.backend_pool_id]
    }
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {}

  lifecycle {
    ignore_changes = [instances]
  }
}

# Purpose: Automatically adjust the VMSS instance count as average CPU load changes.
# Creation: Attach an Azure Monitor autoscale profile to the new scale-set ID with
# default capacity 2 and bounds 1-3. The dynamic map emits two rules: add one
# instance above 70% CPU, remove one below 30%, using five-minute averages and a
# five-minute cooldown. Azure Monitor evaluates these after deployment.
# Important: Bounds limit this scale rule, not total Azure spending. New instances
# still need startup time and healthy web services; tune thresholds/cooldowns for
# real workload behavior and retain the VMSS lifecycle exception for instance count.
resource "azurerm_monitor_autoscale_setting" "this" {
  name                = "${var.name}-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.this.id
  tags                = var.tags

  profile {
    name = "cpu"
    capacity {
      default = 2
      minimum = 1
      maximum = 3
    }

    dynamic "rule" {
      for_each = {
        out = { operator = "GreaterThan", threshold = 70, direction = "Increase" }
        in  = { operator = "LessThan", threshold = 30, direction = "Decrease" }
      }
      content {
        metric_trigger {
          metric_name        = "Percentage CPU"
          metric_resource_id = azurerm_linux_virtual_machine_scale_set.this.id
          time_grain         = "PT1M"
          statistic          = "Average"
          time_window        = "PT5M"
          time_aggregation   = "Average"
          operator           = rule.value.operator
          threshold          = rule.value.threshold
        }
        scale_action {
          direction = rule.value.direction
          type      = "ChangeCount"
          value     = "1"
          cooldown  = "PT5M"
        }
      }
    }
  }
}