terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Reserve the public address clients use to reach the demo web service.
# Creation: Azure creates a static Standard IP and the load balancer's frontend
# references it below; no public IP is attached to either backend VM.
# Important: The IP allocation and load balancer are billable and need a matching
# forwarding rule plus healthy backends before clients receive application responses.
resource "azurerm_public_ip" "this" {
  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Purpose: Create a regional Standard layer-4 load balancer for the web backends.
# Creation: AzureRM creates the load balancer with a frontend named public, using
# the public IP resource above. Pool, probe and rule resources are attached below.
# Important: This forwards TCP traffic; it does not terminate TLS or inspect HTTP
# like Application Gateway/Front Door. The teaching app uses HTTP only and must
# not carry credentials or production data without an appropriate TLS design.
resource "azurerm_lb" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.this.id
  }
}

# Purpose: Define the set of backend network interfaces eligible for load balancing.
# Creation: Add an initially empty pool named web beneath the new load balancer.
# Its ID is used by standalone NIC associations and, optionally, the VMSS module.
# Important: The pool creates no VM or web server. Membership and healthy listeners
# on the backend port are required before it can serve client connections.
resource "azurerm_lb_backend_address_pool" "this" {
  name            = "web"
  loadbalancer_id = azurerm_lb.this.id
}

# Purpose: Register the caller's standalone VM NICs with the web backend pool.
# Creation: for_each adds each named NIC's primary IP configuration to the new pool.
# This matches the primary configuration name defined by the Linux VM module and
# orders membership after the pool and referenced NIC resources are available.
# Important: A differently named NIC IP configuration must be handled deliberately.
# VMSS NICs attach via the scale-set definition, not this standalone NIC collection.
resource "azurerm_network_interface_backend_address_pool_association" "this" {
  for_each                = var.backend_nic_ids
  network_interface_id    = each.value
  ip_configuration_name   = "primary"
  backend_address_pool_id = azurerm_lb_backend_address_pool.this.id
}

# Purpose: Determine which backends are healthy enough to receive new connections.
# Creation: Attach an HTTP probe to the load balancer, requesting / on backend_port
# every five seconds with the configured failure threshold. The forwarding rule
# references this probe's ID, so traffic selection uses this health result.
# Important: The guest must actually serve that path, and NSGs must permit Azure
# load-balancer probes. Creating a VM/NIC does not prove its web server is ready.
resource "azurerm_lb_probe" "this" {
  name                = "http-health"
  loadbalancer_id     = azurerm_lb.this.id
  protocol            = "Http"
  port                = var.backend_port
  request_path        = "/"
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Purpose: Connect the public TCP listening port to the backend pool's service port.
# Creation: Reference the public frontend name, pool ID and probe ID to define how
# incoming connections are distributed to healthy backends. These references order
# the rule after the required load-balancer child resources exist.
# Security: Backend NSGs still need to allow the intended client traffic.
# Important: Outbound SNAT is disabled on this rule because the compute example
# deliberately uses NAT Gateway for egress; an inbound rule is not an egress design.
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