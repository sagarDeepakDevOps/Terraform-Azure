terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81.0, < 5.0.0"
    }
  }
}

# Purpose: Reserve the firewall's public IPv4 address for translated outbound traffic.
# Creation: Azure allocates a static Standard address in the selected group/region;
# its ID is consumed by the firewall IP configuration below.
# Important: An allocated address is billable. No inbound DNAT publishing rule is
# defined in this module, so creating this IP does not publish workload services.
resource "azurerm_public_ip" "this" {
  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Purpose: Separate firewall security settings from the firewall appliance itself.
# Creation: AzureRM creates a Standard policy with threat intelligence in Deny mode
# and DNS proxy capability, then the appliance and rule collection reference it.
# Important: DNS proxy enablement does not change client DNS server settings.
# The application allow-list is defined below; this policy is not a blanket allow
# for every Azure service, and production rules require workload-specific review.
resource "azurerm_firewall_policy" "this" {
  name                     = "${var.name}-policy"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  sku                      = "Standard"
  threat_intelligence_mode = "Deny"
  tags                     = var.tags

  dns {
    proxy_enabled = true
  }
}

# Purpose: Deploy the managed stateful firewall used as the spoke's egress next hop.
# Creation: Azure provisions a Standard VNet firewall in the supplied dedicated
# AzureFirewallSubnet and attaches the public IP and policy created above. Their
# resource IDs and the subnet ID provide Terraform's creation-order dependencies.
# The private IP output is then used by the calling example's VirtualAppliance UDR.
# Important: Use a /26 or larger reserved firewall subnet with no workload NSG.
# Traffic is inspected only if routing sends it through this appliance. Firewall
# has significant hourly/data-processing costs even when the demo is mostly idle.
resource "azurerm_firewall" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.this.id
  tags                = var.tags

  ip_configuration {
    name                 = "primary"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.this.id
  }
}

# Purpose: Allow selected workload CIDRs to reach approved HTTP/HTTPS destinations.
# Creation: Add a priority-200 collection group to the new policy, containing an
# Allow application collection for var.allowed_fqdns on ports 80 and 443. The
# source_address_prefixes input limits which workload ranges may use these rules.
# Important: This is an FQDN application allow-list, not general Internet access;
# other traffic needs appropriate rules. Review destinations and rule ordering
# before adding workloads, and remember that return routes and DNS must also work.
resource "azurerm_firewall_policy_rule_collection_group" "this" {
  name               = "workload-egress"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 200

  application_rule_collection {
    name     = "package-repositories"
    priority = 200
    action   = "Allow"

    rule {
      name              = "approved-packages"
      source_addresses  = var.source_address_prefixes
      destination_fqdns = var.allowed_fqdns

      protocols {
        type = "Http"
        port = 80
      }

      protocols {
        type = "Https"
        port = 443
      }
    }
  }
}