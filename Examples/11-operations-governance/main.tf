# Purpose: Generate a local state-retained suffix for the globally named sample Web App.
# Creation: Random supplies three bytes as hex; no Azure service is deployed by this block.
resource "random_id" "suffix" {
  byte_length = 3
}

# Purpose: Provide a limited lab scope for observability, policy, budget and optional lock.
# Creation: Create the group first; most controls below consume its ARM ID or name.
# Important: The optional Defender module is an explicit subscription-wide exception.
module "resource_group" {
  source   = "../../Modules/ResourceGroups"
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# Purpose: Provide a concrete resource to demonstrate diagnostic export and metric alerts.
# Creation: Create a Linux Web App/plan with a unique hostname; diagnostics and alerts
# use its output ID rather than an unrelated manually entered resource ID.
# Important: The hosting plan is billable and actual application code is deployed separately.
module "web" {
  source              = "../../Modules/AppService"
  name                = "${var.prefix}${random_id.suffix.hex}-app"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

# Purpose: Store platform logs from this lab's explicitly configured diagnostic target.
# Creation: Create LogAnalytics in the lab group; diagnostics and optional Sentinel
# consume its ARM ID. This does not collect all resources across the other examples.
module "logs" {
  source              = "../../Modules/Monitoring/LogAnalytics"
  name                = "${var.prefix}-logs"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

# Purpose: Connect the sample Web App's platform telemetry to the real lab workspace.
# Creation: Pass both created resource IDs to DiagnosticSettings, ordering the export
# after target and destination exist. This is separate from application SDK instrumentation.
module "diagnostics" {
  source             = "../../Modules/Monitoring/DiagnosticSettings"
  target_resource_id = module.web.id
  workspace_id       = module.logs.id
}

# Purpose: Alert the configured operations mailbox when sample Web App HTTP errors rise.
# Creation: Pass the Web App ID and real notification_email into the metric-alert/
# action-group module. Important: A monitored mailbox and response process are still needed.
module "alerts" {
  source              = "../../Modules/Monitoring/Alerts"
  name                = "${var.prefix}-http-errors"
  resource_group_name = module.resource_group.name
  target_resource_id  = module.web.id
  notification_email  = var.notification_email
  tags                = var.tags
}

# Purpose: Demonstrate allowed-region governance within this resource group.
# Creation: Assign the built-in location policy with var.location as its approved list
# and the explicit enforcement flag. DoNotEnforce is the default for safer evaluation;
# enabling enforcement can deny noncompliant future operations, not move existing resources.
module "policy" {
  source            = "../../Modules/Governance/Policy"
  resource_group_id = module.resource_group.id
  allowed_locations = [var.location]
  enforce           = var.enforce_policy
}

# Purpose: Optionally notify about actual/forecast spending for this lab group.
# Creation: count follows enable_budget and passes an explicit valid month start
# plus the operator contact into Budget. Billing permissions/offer support are prerequisites.
# Important: Notifications do not cap spending or stop billable resources.
module "budget" {
  source            = "../../Modules/Governance/Budget"
  count             = var.enable_budget ? 1 : 0
  name              = "${var.prefix}-monthly"
  resource_group_id = module.resource_group.id
  start_date        = var.budget_start_date
  contact_emails    = [var.notification_email]
}

# Purpose: Include a runnable, unscheduled operational PowerShell example.
# Creation: The Automation module creates its account/identity and publishes a small
# status runbook. It does not execute the script or create a recurring schedule on apply.
module "automation" {
  source              = "../../Modules/Automation"
  name                = "${var.prefix}-automation"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

# Purpose: Optionally enable paid Sentinel capabilities on the lab workspace.
# Creation: count follows enable_sentinel; the workspace ID orders onboarding after logs.
# Important: Connectors, analytics rules and SOC processes are not configured by this switch.
module "sentinel" {
  source       = "../../Modules/Security/Sentinel"
  count        = var.enable_sentinel ? 1 : 0
  workspace_id = module.logs.id
}

# Purpose: Demonstrate paid Defender plan management only with explicit owner approval.
# Creation: count follows enable_subscription_defender; the module uses the provider's
# subscription, not module.resource_group's scope, to configure its security plans.
# Important: Reconcile/import existing settings first. This can affect costs/security
# outside the lab, and removing it can change coverage for those other resources.
module "defender" {
  source = "../../Modules/Security/Defender"
  count  = var.enable_subscription_defender ? 1 : 0
}

# Purpose: Optionally protect the lab resource group against accidental Azure deletion.
# Creation: Add CanNotDelete only after all listed group resources/controls are created,
# as specified by depends_on. Terraform can remove the lock during an authorized teardown.
# Important: The lock is not a backup, a billing cap or protection for subscription-wide
# Defender settings; review retained data and security scope separately before cleanup.
module "lock" {
  source = "../../Modules/Governance/Locks"
  count  = var.enable_lock ? 1 : 0
  scope  = module.resource_group.id

  depends_on = [module.web, module.logs, module.diagnostics, module.alerts, module.policy, module.budget, module.automation, module.sentinel]
}