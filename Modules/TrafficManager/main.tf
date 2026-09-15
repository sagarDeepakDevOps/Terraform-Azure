terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Select an available application endpoint through global DNS priority routing.
# Creation: Azure creates the profile's trafficmanager.net name with a 30-second
# TTL and an HTTPS / health monitor on port 443. The external endpoints below supply
# candidates; healthy candidates with lower numeric priority are preferred.
# Important: Traffic Manager returns DNS answers, not proxied HTTP responses, and
# does not terminate TLS. Monitor/caching delays mean failover is not instantaneous.
# Backend applications must independently support the hostname/certificate clients use.
resource "azurerm_traffic_manager_profile" "this" {
  name                   = var.name
  resource_group_name    = var.resource_group_name
  traffic_routing_method = "Priority"
  tags                   = var.tags

  dns_config {
    relative_name = var.name
    ttl           = 30
  }

  monitor_config {
    protocol                     = "HTTPS"
    port                         = 443
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 10
    tolerated_number_of_failures = 3
  }
}

# Purpose: Register each independently hosted application as a DNS failover candidate.
# Creation: for_each adds a named external FQDN and priority to the profile above.
# The supplied hostnames must already serve the expected HTTPS health-check path;
# Terraform does not provision those applications from this endpoint registration.
# Important: Use at least two real endpoints with unique priorities, and configure
# their client-facing domains/TLS and data consistency before claiming regional DR.
resource "azurerm_traffic_manager_external_endpoint" "this" {
  for_each   = var.endpoints
  name       = each.key
  profile_id = azurerm_traffic_manager_profile.this.id
  target     = each.value.hostname
  priority   = each.value.priority
}