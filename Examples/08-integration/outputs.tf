output "service_bus_endpoint" {
  description = "Service Bus endpoint for Entra-authenticated clients."
  value       = module.service_bus.endpoint
}

output "local_authentication" {
  description = "Shared-key authentication settings for messaging services."
  value = {
    service_bus = module.service_bus.local_auth_enabled
    event_hubs  = module.event_hubs.local_authentication_enabled
  }
}

output "workflow_enabled" {
  description = "Whether the daily workflow executes."
  value       = module.workflow.enabled
}

output "api_demo_url" {
  description = "Optional APIM health endpoint; requires a subscription key."
  value       = var.enable_api_management ? module.api_management[0].demo_url : null
}