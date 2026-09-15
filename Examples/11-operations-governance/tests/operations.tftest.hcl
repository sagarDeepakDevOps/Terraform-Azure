mock_provider "azurerm" {}
mock_provider "random" {}

variables {
  notification_email = "platform@example.com"
}

run "safe_governance_defaults" {
  command = plan

  assert {
    condition     = !output.policy_enforced && !output.subscription_defender_enabled
    error_message = "Policy enforcement and subscription-wide billing/security changes must be opt-in."
  }

  assert {
    condition     = output.runbook_name == "show-demo-context"
    error_message = "The Automation account must include a runnable example."
  }
}

run "governance_options" {
  command = plan

  variables {
    enable_budget                = true
    budget_start_date            = "2026-09-01T00:00:00Z"
    enable_lock                  = true
    enable_sentinel              = true
    enable_subscription_defender = true
    enforce_policy               = true
  }

  assert {
    condition     = output.policy_enforced && output.subscription_defender_enabled
    error_message = "Explicitly selected governance options must be wired correctly."
  }
}