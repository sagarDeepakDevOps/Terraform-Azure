terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Create the global Front Door service that owns endpoints and delivery policy.
# Creation: AzureRM provisions a Premium_AzureFrontDoor profile in the resource group;
# child resources use its ID, while its resource_guid identifies this profile to an
# origin's X-Azure-FDID restriction. Those two identifiers are not interchangeable.
# Important: Premium is selected for the managed WAF rules shown here and has a base
# charge. The profile alone publishes no application route or protected origin.
resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  sku_name            = "Premium_AzureFrontDoor"
  tags                = var.tags
}

# Purpose: Create the Azure-managed public hostname where clients enter Front Door.
# Creation: Add an endpoint under the new profile; Azure returns its default host_name
# for HTTPS access. The route and WAF security association below target this endpoint.
# Important: This is the default Azure hostname. A customer-owned domain still needs
# ownership validation, certificate handling and an explicit custom-domain binding.
resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = var.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  tags                     = var.tags
}

# Purpose: Define the health and load-selection policy for the backend origin set.
# Creation: Add an application origin group to the profile with HTTPS GET / probes
# every 60 seconds and a health sample requiring three successes out of four.
# The origin below joins this group and the route uses the group to select a backend.
# Important: Configure a genuinely healthy application path and permit Front Door's
# origin traffic. Creating the group does not deploy or repair a backend application.
resource "azurerm_cdn_frontdoor_origin_group" "this" {
  name                     = "application"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/"
    protocol            = "Https"
    request_type        = "GET"
    interval_in_seconds = 60
  }
}

# Purpose: Register the actual HTTPS application host behind Front Door.
# Creation: Add var.origin_hostname to the new group with that same HTTP Host header,
# certificate-name checking, priority 1 and weight 1000. Referencing a Web App output
# makes Terraform wait for the backend hosting resource before registering it.
# Important: The origin must serve a trusted certificate matching its host and pass
# health checks. The caller restricts direct origin access separately; this resource
# is not itself an origin firewall or an application-code deployment.
resource "azurerm_cdn_frontdoor_origin" "this" {
  name                           = "web"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.this.id
  host_name                      = var.origin_hostname
  origin_host_header             = var.origin_hostname
  http_port                      = 80
  https_port                     = 443
  certificate_name_check_enabled = true
  priority                       = 1
  weight                         = 1000
}

# Purpose: Route requests arriving at the public endpoint to the configured application.
# Creation: Join the endpoint, origin group and origin IDs with a /* path match and
# enable the default domain. HTTP clients are redirected to HTTPS, and Front Door
# forwards to the origin using HTTPS regardless of the client's initial protocol.
# Important: This configures HTTP delivery, not DNS failover or layer-4 balancing.
# It does not add application authentication or a caching policy automatically.
resource "azurerm_cdn_frontdoor_route" "this" {
  name                          = "https-app"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.this.id]
  supported_protocols           = ["Http", "Https"]
  patterns_to_match             = ["/*"]
  forwarding_protocol           = "HttpsOnly"
  https_redirect_enabled        = true
  link_to_default_domain        = true
}

# Purpose: Define managed web-application filtering for this Front Door profile.
# Creation: AzureRM creates a Premium-compatible WAF policy in Prevention mode with
# Microsoft_DefaultRuleSet 2.1 set to Block; replace removes hyphens from its name
# to fit this resource's naming rules. The security policy below attaches it.
# Important: Defining WAF rules without attaching them does not protect an endpoint.
# Tune and monitor false positives for a real application; WAF is not user authorization.
resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  name                = replace(var.name, "-", "")
  resource_group_name = var.resource_group_name
  sku_name            = azurerm_cdn_frontdoor_profile.this.sku_name
  enabled             = true
  mode                = "Prevention"
  tags                = var.tags

  managed_rule {
    type    = "Microsoft_DefaultRuleSet"
    version = "2.1"
    action  = "Block"
  }
}

# Purpose: Make the WAF policy effective on the Front Door endpoint's request paths.
# Creation: Associate the WAF policy ID with the endpoint domain ID for /* under
# the same profile. References order this binding after profile, endpoint and WAF.
# Important: New domains/routes need an appropriate association too. This protects
# traffic through Front Door; direct-origin restrictions must be enforced on the origin.
resource "azurerm_cdn_frontdoor_security_policy" "this" {
  name                     = "waf"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this.id
      association {
        patterns_to_match = ["/*"]
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.this.id
        }
      }
    }
  }
}