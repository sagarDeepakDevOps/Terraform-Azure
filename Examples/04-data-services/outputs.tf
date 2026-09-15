output "selected_databases" {
  description = "Database engine selection."
  value       = var.databases
}

output "storage_security" {
  description = "Storage security settings."
  value       = module.storage.security
}

output "private_endpoint_services" {
  description = "Services with private endpoints and matching private DNS zones."
  value       = keys(local.private_services)
}

output "sql_fqdn" {
  description = "Private SQL endpoint; connect from a VNet-linked client."
  value       = var.databases.sql ? module.sql[0].fqdn : null
}

output "database_admin_password" {
  description = "Generated demo password. Retrieve only when needed; never paste it into slides or logs."
  value       = random_password.database.result
  sensitive   = true
}

output "key_vault_uri" {
  description = "Private vault endpoint. Secret values are deliberately not written from a public runner."
  value       = module.key_vault.uri
}

output "additional_database_endpoints" {
  description = "Normal service hostnames that resolve privately from linked clients."
  value = {
    postgresql = var.databases.postgresql ? module.postgresql[0].fqdn : null
    mysql      = var.databases.mysql ? module.mysql[0].fqdn : null
    cosmos     = var.databases.cosmos ? module.cosmos[0].endpoint : null
    redis      = var.databases.redis ? module.redis[0].hostname : null
    redis_port = var.databases.redis ? module.redis[0].port : null
  }
}