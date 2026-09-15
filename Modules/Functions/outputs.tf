output "id" {
  description = "Flex Consumption Function App ID."
  value       = azurerm_function_app_flex_consumption.this.id
}

output "hostname" {
  description = "Function App hostname. Deploy a function package before invoking application routes."
  value       = azurerm_function_app_flex_consumption.this.default_hostname
}

output "storage_authentication_type" {
  description = "Storage authentication mode, without any access key."
  value       = azurerm_function_app_flex_consumption.this.storage_authentication_type
}