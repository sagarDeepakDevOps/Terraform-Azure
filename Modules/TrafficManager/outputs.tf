output "fqdn" {
  description = "Traffic Manager DNS name. Each backend still needs the client-facing custom hostname and certificate."
  value       = azurerm_traffic_manager_profile.this.fqdn
}