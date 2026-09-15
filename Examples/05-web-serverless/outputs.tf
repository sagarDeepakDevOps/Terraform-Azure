output "web_url" {
  description = "App Service URL. Hosting exists before application code is deployed."
  value       = "https://${module.web.hostname}"
}

output "function_url" {
  description = "Function App URL. No application function package is deployed by this infrastructure example."
  value       = "https://${module.functions.hostname}"
}

output "web_https_only" {
  description = "HTTPS enforcement on App Service."
  value       = module.web.https_only
}

output "function_storage_authentication" {
  description = "Function deployment storage authentication mode."
  value       = module.functions.storage_authentication_type
}