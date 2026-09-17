output "subnet_ids" {
  description = "Subnet IDs keyed by VNet short name, then subnet name. Later exercises look subnets up by name instead."
  value       = { for key, subnets in module.subnets : key => subnets.ids }
}
