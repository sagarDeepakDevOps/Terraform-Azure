output "container_app_url" {
  description = "Runnable public HTTPS sample container."
  value       = "https://${module.apps.hostname}"
}

output "registry_login_server" {
  description = "Private-image registry with an authenticated public endpoint in this Basic SKU lab."
  value       = module.registry.login_server
}

output "registry_admin_enabled" {
  description = "Whether ACR shared administrator credentials are enabled."
  value       = module.registry.admin_enabled
}

output "aks_private" {
  description = "AKS API privacy when the optional cluster is selected."
  value       = var.enable_aks ? module.aks[0].private_cluster_enabled : null
}

output "aks_name" {
  description = "Optional private cluster name; its credentials are deliberately not exported."
  value       = var.enable_aks ? module.aks[0].name : null
}