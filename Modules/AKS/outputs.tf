output "id" {
  description = "AKS cluster resource ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "Cluster name for az aks get-credentials from a connected client."
  value       = azurerm_kubernetes_cluster.this.name
}

output "oidc_issuer_url" {
  description = "Issuer for federated workload identity credentials."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "private_cluster_enabled" {
  description = "Whether the Kubernetes API is private."
  value       = azurerm_kubernetes_cluster.this.private_cluster_enabled
}