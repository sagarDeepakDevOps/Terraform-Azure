terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Reserve the Linux App Service hosting tier used by the Web App below.
# Creation: AzureRM creates a plan in the selected group/region with var.sku_name;
# the app references the resulting plan ID instead of provisioning its own VMs.
# Important: Choose a SKU supporting this app's Always On and VNet features. A
# provisioned plan can cost money even before application code or traffic exists.
resource "azurerm_service_plan" "this" {
  name                = "${var.name}-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

# Purpose: Create a managed Node 22 Web App with HTTPS and a workload identity.
# Creation: Azure provisions the globally named site on the Linux plan above and
# applies runtime/settings after the plan exists. An optional delegated subnet
# enables outbound VNet integration and route-all, so its egress must be configured.
# Security: Require TLS 1.2, disable FTP/basic publishing credentials, and create a
# system-assigned identity. When front_door_only is true, emit one allow rule for
# the Front Door service tag plus the specific profile GUID, then deny other requests.
# Otherwise this configuration permits public application ingress over HTTPS.
# Important: VNet integration is not a private inbound endpoint or user login policy.
# No application package is deployed here; settings may contain sensitive values
# retained in state. Grant identity access, instrument/deploy the app and verify
# its health through the intended ingress path before calling the deployment ready.
resource "azurerm_linux_web_app" "this" {
  name                                           = var.name
  resource_group_name                            = var.resource_group_name
  location                                       = var.location
  service_plan_id                                = azurerm_service_plan.this.id
  https_only                                     = true
  virtual_network_subnet_id                      = var.integration_subnet_id
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  app_settings                                   = var.app_settings
  tags                                           = var.tags

  site_config {
    always_on                     = true
    minimum_tls_version           = "1.2"
    scm_minimum_tls_version       = "1.2"
    ftps_state                    = "Disabled"
    http2_enabled                 = true
    vnet_route_all_enabled        = var.integration_subnet_id != null
    ip_restriction_default_action = var.front_door_only ? "Deny" : "Allow"

    application_stack {
      node_version = "22-lts"
    }

    dynamic "ip_restriction" {
      for_each = var.front_door_only ? [true] : []
      content {
        name        = "front-door-only"
        priority    = 100
        action      = "Allow"
        service_tag = "AzureFrontDoor.Backend"
        headers {
          x_azure_fdid = [var.front_door_id]
        }
      }
    }
  }

  identity {
    type = "SystemAssigned"
  }
}