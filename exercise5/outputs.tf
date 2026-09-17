output "peering_ids" {
  description = "Both directional peering IDs for each configured peering."
  value       = { for key, peering in module.peerings : key => peering.ids }
}
