output "id" {
  description = "Front Door profile ARM ID."
  value       = azurerm_cdn_frontdoor_profile.this.id
}

output "resource_guid" {
  description = "Front Door GUID used in origin X-Azure-FDID restrictions."
  value       = azurerm_cdn_frontdoor_profile.this.resource_guid
}

output "hostname" {
  description = "Public HTTPS Front Door hostname."
  value       = azurerm_cdn_frontdoor_endpoint.this.host_name
}

output "waf_mode" {
  description = "Managed WAF operating mode."
  value       = azurerm_cdn_frontdoor_firewall_policy.this.mode
}