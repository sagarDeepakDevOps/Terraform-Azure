terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Frontend IP, skipped when the caller supplies one to avoid a module cycle; the DNS label must be region-unique.
resource "azurerm_public_ip" "this" {
  count = var.existing_public_ip == null ? 1 : 0

  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.domain_name_label
  tags                = var.tags
}

# Splat instead of [0] so neither branch fails with an index error when count is 0.
locals {
  public_ip_id      = var.existing_public_ip != null ? var.existing_public_ip.id : one(azurerm_public_ip.this[*].id)
  public_ip_address = var.existing_public_ip != null ? var.existing_public_ip.ip_address : one(azurerm_public_ip.this[*].ip_address)
  public_ip_fqdn    = var.existing_public_ip != null ? var.existing_public_ip.fqdn : one(azurerm_public_ip.this[*].fqdn)
}

# Layer-4 only, with no VNet of its own: the pool takes its network from the NICs added to it, so all backends share one VNet.
resource "azurerm_lb" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = local.public_ip_id
  }
}

# Starts empty; membership plus a healthy listener are both required before traffic flows.
resource "azurerm_lb_backend_address_pool" "this" {
  name            = "web"
  loadbalancer_id = azurerm_lb.this.id
}

# Keys must be known at plan time, so callers key this map by VM name rather than by NIC ID.
resource "azurerm_network_interface_backend_address_pool_association" "this" {
  for_each                = var.backend_nic_ids
  network_interface_id    = each.value
  ip_configuration_name   = "primary"
  backend_address_pool_id = azurerm_lb_backend_address_pool.this.id
}

# The backend NSG must allow the AzureLoadBalancer service tag, or every probe fails and the frontend answers nothing.
resource "azurerm_lb_probe" "this" {
  name                = "http-health"
  loadbalancer_id     = azurerm_lb.this.id
  protocol            = "Http"
  port                = var.backend_port
  request_path        = "/"
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Outbound SNAT is off because each backend carries its own public IP for egress.
resource "azurerm_lb_rule" "this" {
  name                           = "http"
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = "Tcp"
  frontend_port                  = var.frontend_port
  backend_port                   = var.backend_port
  frontend_ip_configuration_name = "public"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this.id]
  probe_id                       = azurerm_lb_probe.this.id
  disable_outbound_snat          = true
}
