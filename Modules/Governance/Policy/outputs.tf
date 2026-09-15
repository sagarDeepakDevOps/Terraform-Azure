output "id" {
  description = "Resource group policy assignment ID."
  value       = azurerm_resource_group_policy_assignment.this.id
}

output "enforce" {
  description = "Whether the policy can deny new deployments."
  value       = azurerm_resource_group_policy_assignment.this.enforce
}