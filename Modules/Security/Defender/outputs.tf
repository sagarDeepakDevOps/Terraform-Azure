output "ids" {
  description = "Subscription pricing setting IDs. Destroying these can change security coverage; review separately from demo cleanup."
  value       = { for name, plan in azurerm_security_center_subscription_pricing.this : name => plan.id }
}