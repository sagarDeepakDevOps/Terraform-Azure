output "ids" {
  description = "Role assignment IDs keyed by input name."
  value       = { for name, assignment in azurerm_role_assignment.this : name => assignment.id }
}