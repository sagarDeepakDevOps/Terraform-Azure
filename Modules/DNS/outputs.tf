output "id" {
  description = "Public DNS zone ID."
  value       = azurerm_dns_zone.this.id
}

output "name_servers" {
  description = "Delegate these authoritative nameservers at the domain registrar when using a real owned domain."
  value       = azurerm_dns_zone.this.name_servers
}