output "nsg_ids" {
  description = "NSG resource IDs keyed by the nsgs map key."
  value       = { for key, nsg in module.nsgs : key => nsg.id }
}
