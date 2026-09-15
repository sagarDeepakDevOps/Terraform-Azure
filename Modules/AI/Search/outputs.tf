output "id" {
  description = "Search service ID for RBAC and a searchService private endpoint."
  value       = azurerm_search_service.this.id
}

output "endpoint" {
  description = "Private Search endpoint; callers need appropriate Search data/service roles."
  value       = azurerm_search_service.this.endpoint
}

output "local_authentication_enabled" {
  description = "Whether Search API keys are accepted."
  value       = azurerm_search_service.this.local_authentication_enabled
}