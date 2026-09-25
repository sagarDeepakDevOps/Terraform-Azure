# Azure evaluates DNAT first, then network rules, then application rules; anything unmatched is denied.
resource "azurerm_firewall_policy_rule_collection_group" "this" {
  name               = var.name
  firewall_policy_id = var.firewall_policy_id
  priority           = var.priority

  dynamic "nat_rule_collection" {
    for_each = length(var.dnat_rules) > 0 ? [1] : []
    content {
      name     = "inbound-dnat"
      priority = 100
      action   = "Dnat"

      dynamic "rule" {
        for_each = var.dnat_rules
        content {
          name                = rule.key
          protocols           = rule.value.protocols
          source_addresses    = rule.value.source_addresses
          destination_address = rule.value.destination_address
          destination_ports   = rule.value.destination_ports
          translated_address  = rule.value.translated_address
          translated_port     = rule.value.translated_port
        }
      }
    }
  }

  dynamic "network_rule_collection" {
    for_each = length(var.network_rules) > 0 ? [1] : []
    content {
      name     = "east-west"
      priority = 200
      action   = "Allow"

      dynamic "rule" {
        for_each = var.network_rules
        content {
          name                  = rule.key
          protocols             = rule.value.protocols
          source_addresses      = rule.value.source_addresses
          destination_addresses = rule.value.destination_addresses
          destination_ports     = rule.value.destination_ports
        }
      }
    }
  }

  dynamic "application_rule_collection" {
    for_each = length(var.application_rules) > 0 ? [1] : []
    content {
      name     = "egress"
      priority = 300
      action   = "Allow"

      dynamic "rule" {
        for_each = var.application_rules
        content {
          name              = rule.key
          source_addresses  = rule.value.source_addresses
          destination_fqdns = rule.value.destination_fqdns

          dynamic "protocols" {
            for_each = rule.value.protocols
            content {
              type = protocols.value.type
              port = protocols.value.port
            }
          }
        }
      }
    }
  }
}
