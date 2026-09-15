output "id" {
  description = "OpenAI account ID for RBAC and private endpoints."
  value       = azurerm_cognitive_account.this.id
}

output "endpoint" {
  description = "Private OpenAI endpoint. The caller also needs a deployment name and Cognitive Services OpenAI User role."
  value       = azurerm_cognitive_account.this.endpoint
}

output "deployment_names" {
  description = "Model deployment names, distinct from underlying model names."
  value       = keys(azurerm_cognitive_deployment.this)
}