terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Host authoritative public DNS records for the chosen domain namespace.
# Creation: AzureRM creates the zone and Azure assigns authoritative nameservers;
# the module outputs those nameservers for delegation at the domain's registrar.
# Important: Zone creation does not buy/register the domain or change its registrar.
# Without delegation, public resolvers do not automatically use these new records.
resource "azurerm_dns_zone" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Purpose: Map selected relative DNS names to one or more IPv4 addresses.
# Creation: for_each creates an A record set per input key beneath the new zone,
# using the supplied address list and a 300-second DNS TTL. The zone reference
# orders creation, while endpoint-derived addresses can add their own dependencies.
# Important: DNS resolution does not open a firewall, create a listener or install
# a TLS certificate, and resolver caches delay how quickly changes become visible.
resource "azurerm_dns_a_record" "this" {
  for_each            = var.a_records
  name                = each.key
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = each.value
  tags                = var.tags
}

# Purpose: Alias a relative DNS name to another service's fully qualified hostname.
# Creation: for_each adds a CNAME per input key under this zone with a 300-second
# TTL; a Front Door hostname output, for example, orders that target's creation.
# Important: A CNAME is not TLS termination or service-side custom-domain binding.
# Complete ownership/certificate setup at the target before advertising the alias,
# and use a suitable apex-record design instead of an ordinary apex CNAME.
resource "azurerm_dns_cname_record" "this" {
  for_each            = var.cname_records
  name                = each.key
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  record              = each.value
  tags                = var.tags
}