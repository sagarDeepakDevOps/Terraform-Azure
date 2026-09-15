output "ids" {
  description = "Both directional peering IDs."
  value = {
    first_to_second = azurerm_virtual_network_peering.first_to_second.id
    second_to_first = azurerm_virtual_network_peering.second_to_first.id
  }
}