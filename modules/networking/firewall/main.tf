# Spokes' Internet egress leaves from this address, and published apps are reached on it.
resource "azurerm_public_ip" "data" {
  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Basic tier only: Azure manages the firewall over this address, and it never carries workload traffic.
resource "azurerm_public_ip" "management" {
  count = var.sku_tier == "Basic" ? 1 : 0

  name                = "${var.name}-mgmt-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Rules live on the policy rather than the firewall, so they can change without redeploying it.
resource "azurerm_firewall_policy" "this" {
  name                = "${var.name}-policy"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku_tier
  tags                = var.tags
}

# Child module holding every rule; DNAT targets the data public IP above.
module "rules" {
  source = "./rule-collection-group"

  name               = "hub-baseline"
  firewall_policy_id = azurerm_firewall_policy.this.id
  dnat_rules         = { for key, rule in var.dnat_rules : key => merge(rule, { destination_address = azurerm_public_ip.data.ip_address }) }
  network_rules      = var.network_rules
  application_rules  = var.application_rules
}

# Built after its rules, so spokes never route through a firewall that is still denying everything.
resource "azurerm_firewall" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = var.sku_tier
  firewall_policy_id  = azurerm_firewall_policy.this.id
  tags                = var.tags

  ip_configuration {
    name                 = "data"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.data.id
  }

  dynamic "management_ip_configuration" {
    for_each = var.sku_tier == "Basic" ? [1] : []
    content {
      name                 = "management"
      subnet_id            = var.management_subnet_id
      public_ip_address_id = azurerm_public_ip.management[0].id
    }
  }

  depends_on = [module.rules]
}
