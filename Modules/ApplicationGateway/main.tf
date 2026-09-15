terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Allocate the regional gateway's public HTTPS listening address.
# Creation: AzureRM reserves a static Standard public IP and passes its ID into
# the Application Gateway frontend below. A real domain should resolve to it.
# Important: Clients must use the listener's certificate hostname, not merely this
# numeric address. IP allocation and the gateway both incur charges.
resource "azurerm_public_ip" "this" {
  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Purpose: Define regional web-request filtering separately from the gateway appliance.
# Creation: Create an enabled WAF policy using OWASP 3.2 managed rules in Prevention
# mode; the gateway's firewall_policy_id attaches it to the listener traffic path.
# Important: Review application compatibility and false positives before production.
# A WAF policy does not implement user authentication, backend authorization or DNS.
resource "azurerm_web_application_firewall_policy" "this" {
  name                = "${var.name}-waf"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  policy_settings {
    enabled = true
    mode    = "Prevention"
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

# Purpose: Create a regional HTTPS reverse proxy with WAF for the supplied backends.
# Creation: Azure provisions WAF_v2 in a dedicated subnet and joins the public IP,
# WAF policy, HTTPS frontend, certificate and listener. Named routing blocks connect
# the listener to the application backend pool and https-backend settings; resource
# references provide ordering for the IP/policy/subnet prerequisites.
# TLS: The supplied base64 PFX/password configure client-facing TLS with SNI and the
# chosen SSL policy. A separate HTTPS leg connects to backend FQDNs, using their host
# names and trusted certificates. The / health probe controls backend eligibility.
# Capacity: Autoscaling is bounded at 1-2 gateway instances for this demonstration.
# Important: This creates no backend application, certificate or DNS record. The PFX
# private key/password remain sensitive in state; production should use a reviewed
# Key Vault certificate design. Check reserved subnet needs, healthy backends and
# significant fixed/usage costs before applying, even when no users are connected.
resource "azurerm_application_gateway" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  firewall_policy_id  = azurerm_web_application_firewall_policy.this.id
  tags                = var.tags

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 2
  }

  gateway_ip_configuration {
    name      = "primary"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.this.id
  }

  frontend_port {
    name = "https"
    port = 443
  }

  ssl_certificate {
    name     = "listener"
    data     = var.certificate_base64
    password = var.certificate_password
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101S"
  }

  http_listener {
    name                           = "https"
    frontend_ip_configuration_name = "public"
    frontend_port_name             = "https"
    protocol                       = "Https"
    ssl_certificate_name           = "listener"
    host_name                      = var.listener_hostname
    require_sni                    = true
  }

  backend_address_pool {
    name  = "application"
    fqdns = var.backend_hostnames
  }

  backend_http_settings {
    name                                = "https-backend"
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
    probe_name                          = "health"
  }

  probe {
    name                                      = "health"
    protocol                                  = "Https"
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 20
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  request_routing_rule {
    name                       = "application"
    rule_type                  = "Basic"
    priority                   = 100
    http_listener_name         = "https"
    backend_address_pool_name  = "application"
    backend_http_settings_name = "https-backend"
  }
}