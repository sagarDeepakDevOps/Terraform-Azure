output "ai_services_endpoint" {
  description = "Private multi-service AI endpoint."
  value       = module.cognitive.endpoint
}

output "search_endpoint" {
  description = "Private AI Search endpoint; create indexes through its data API from an authorized client."
  value       = module.search.endpoint
}

output "search_local_authentication" {
  description = "Whether Search accepts API keys."
  value       = module.search.local_authentication_enabled
}

output "openai_deployments" {
  description = "Selected model deployment names."
  value       = var.enable_openai ? module.openai[0].deployment_names : []
}

output "ml_storage_access" {
  description = "Storage authentication mode for the optional ML workspace."
  value       = var.enable_machine_learning ? module.machine_learning[0].storage_account_access_type : null
}