output "resource_group_name" {
  description = "Pass this into exercise2 as resource_group_name."
  value       = module.resource_group.name
}

output "location" {
  description = "Region the group was created in; later exercises read it from the group itself."
  value       = module.resource_group.location
}
