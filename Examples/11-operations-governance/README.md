# 11: Operations, Security and Governance

Creates a sample Web App, Log Analytics, diagnostic export, an HTTP 5xx metric alert/email action group, an Allowed locations policy in DoNotEnforce mode, and an Automation account with a PowerShell runbook. A real `notification_email` is required for a live deployment.

## Optional Controls

| Input | Scope and prerequisite |
| --- | --- |
| `enforce_policy` | Enables the location policy's Deny behavior within this lab's resource group |
| `enable_budget` | Creates actual/forecast monthly budget alerts; also requires a valid `budget_start_date` and billing permissions |
| `enable_lock` | Adds CanNotDelete protection to this lab resource group; remove deliberately before teardown |
| `enable_sentinel` | Onboards the lab's Log Analytics workspace to paid Sentinel; connectors/rules are separate |
| `enable_subscription_defender` | **Subscription-wide** paid security settings, not limited to this resource group; requires owner approval and reconciliation/import of existing settings |

The budget timestamp must be the first day of the current or an allowed future month. It is deliberately not derived from `timestamp()` and not hardcoded into deployment defaults. A budget notifies; it does not prevent spending.

## What to Demonstrate

Show the diagnostic-setting target/workspace relationship, the alert's action group, the policy's enforcement setting and the manual-run `show-demo-context` Automation runbook. The runbook has no schedule and requires no external PowerShell module or cloud credential for its harmless status output.

This observability configuration targets the sample Web App, not every resource in all examples. Deploy/instrument a real application to generate useful application telemetry. Sentinel onboarding is not equivalent to SOC coverage, and Defender settings are not a security certification.

## Validate and Clean Up

```bash
bash scripts/validate.sh 11-operations-governance
```

Tests cover non-enforcing defaults and all explicitly selected options. Read [Docs/SECURITY-AND-COST.md](../../Docs/SECURITY-AND-COST.md) before changing Defender settings or destroying this root, and [Docs/DEPLOYMENT.md](../../Docs/DEPLOYMENT.md) for permissions.