output "policy_enforced" {
  description = "Whether the location policy is enforcing Deny."
  value       = module.policy.enforce
}

output "subscription_defender_enabled" {
  description = "Whether subscription-wide paid Defender plans are managed by this lab."
  value       = var.enable_subscription_defender
}

output "runbook_name" {
  description = "Manual-run Automation example."
  value       = module.automation.runbook_name
}

output "action_group_id" {
  description = "Operations notification group."
  value       = module.alerts.action_group_id
}