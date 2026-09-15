output "id" {
  description = "API Management service ID."
  value       = azurerm_api_management.this.id
}

output "demo_url" {
  description = "Health operation URL; requires a valid APIM subscription key. Create/approve a subscription in APIM before invoking."
  value       = "${azurerm_api_management.this.gateway_url}/demo/health"
}