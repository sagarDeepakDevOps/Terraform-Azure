# Security, Cost and Cleanup

## Security Decisions

- No subscription, tenant, customer credential or private key is hardcoded in the examples. Test GUIDs, addresses, passwords and certificates are mock fixtures.
- Workload VMs have no public NIC addresses. SSH uses a public key; Windows passwords are sensitive inputs. The compute lab deliberately does not open remote administration.
- Subnets disable default outbound access. Compute/container/hosting paths explicitly provide NAT; the secure-hub example uses its firewall and route table.
- Data, Key Vault and AI examples disable public access and create private endpoints or delegated database subnets with DNS links.
- ACR disables shared administrator credentials. Cosmos DB, Search, Service Bus, Event Hubs and AI account examples use Entra authentication.
- Key Vault has RBAC authorization and purge protection. No example weakens purge protection to make teardown easier.
- HTTPS/TLS is enforced for managed web/AI/database endpoints. The Standard Load Balancer example intentionally serves only non-sensitive HTTP sample content.
- SQL/PostgreSQL/MySQL share one generated demo administrator password in example 04, and Managed Redis uses a demo access key. Production requires separate workload credentials or identity authentication, rotation and least-privilege database users.
- Storage Files shares are created without shared keys. Configure a supported SMB identity/domain model before mounting; a created file share is not an end-to-end file-server deployment.
- Some cost-oriented platform examples expose authenticated public endpoints: Basic ACR, Standard Service Bus/Event Hubs, Databricks UI and web/API ingress. These are explicit demo tradeoffs, not a claim that every service is private.

## State and Secret Handling

`sensitive = true` hides values in normal CLI output; it does not encrypt them inside state or saved plan files. Providers can also return service credentials into state even when a module does not export them. Protect all state as confidential.

Never publish state, plan files, actual `.tfvars`, private keys, PFX data, connection strings, kubeconfigs, access tokens or password outputs. Do not use `terraform show -json` output in slides without sanitizing it. Retain only reviewed code, `.tfvars.example`, tests and provider lock files in Git.

State storage uses Entra authorization, restricted network access, ZRS, versioning, soft deletion and a management lock. Blob leases provide Terraform's state locking; that is distinct from a CanNotDelete Azure management lock. A management lock can be removed by authorized Terraform, so it does not make a destructive Terraform plan harmless.

## Cost Guide

Do not quote fixed prices from this repository. Azure prices vary by region, agreement, currency, usage and time. Use the [Azure pricing calculator](https://azure.microsoft.com/pricing/calculator/) before every client demonstration.

| Example | Main recurring/usage cost drivers |
| --- | --- |
| 01 | Private DNS zones/queries and peering data transfer; VNet/subnet/NSG/UDR objects have no standalone hourly appliance fee |
| 02 | Two VM instances/disks, LB, NAT, public IPs and traffic; optional Windows/VMSS/backup |
| 03 | Standard Firewall hourly and data processing charges; optional Bastion and VPN Gateway can be substantial |
| 04 | Storage operations/capacity, each selected database engine, Private Link endpoints and DNS; Redis is billable while idle |
| 05 | App Service plan, Flex execution, NAT, endpoints, storage and telemetry |
| 06 | ACR, Container Apps activity/environment networking, NAT, logs; optional AKS VM nodes/disks remain billable even with a Free control-plane tier |
| 07 | Front Door Premium base/usage/WAF, Web App plan, DNS; optional WAF_v2 gateway adds significant fixed cost |
| 08 | Service Bus/Event Hubs namespace capacity, event delivery, storage/endpoints; APIM Developer has fixed cost; workflow actions cost when run |
| 09 | Lake/endpoints, pipeline activity, optional Databricks networking and Synapse usage; no clusters or dedicated pools are automatically created |
| 10 | Search provisioned capacity, Private Link and API/model usage; later ML compute and managed-network resources add cost |
| 11 | Web App, telemetry, alert rules, Automation usage; Sentinel and Defender add paid security coverage |
| Bootstrap | Durable state storage and operations; intentionally kept after demo workloads are deleted |

Budgets send notifications, not hard spending caps. Log Analytics quotas can drop telemetry and are not a billing guarantee. Stopping a VM does not remove charges for disks, NAT, gateways, public IPs, backups or other services. Some gateway and platform deployments can take tens of minutes or longer, so do not provision the expensive labs live during a short PPT session.

## Scope-Wide Changes

The Defender module manages subscription-wide pricing/security settings, not merely the demo resource group. It is off by default. Obtain subscription-owner approval, inspect existing settings and import them before adopting them into this state. Turning the flag off or destroying the lab may remove/downgrade those settings. Reconcile security coverage deliberately rather than treating it as ordinary demo cleanup.

The location policy is resource-group scoped and defaults to DoNotEnforce. Enforcement can block future resources. Sentinel onboarding does not include data connectors, detection content, incident response or a security operations process.

## Cleanup Runbook

1. Identify the exact example, subscription, backend key and owner. Preserve any required data and recovery evidence.
2. Review optional backup, lock, policy and subscription-wide settings before creating a destroy plan.
3. For a selected resource-group lock, set `enable_lock = false`, review that change and apply it before teardown when necessary. Never remove locks from unrelated scopes.
4. For VM Backup, stop protection and handle retained recovery points according to the approved retention policy. Azure secure-by-default soft deletion can prevent immediate empty-vault deletion. Do not disable security controls simply to complete a demo cleanup.
5. Review vault/service soft-deletion behavior. Key Vault purge protection prevents immediate purge/name reuse. Cognitive services can retain deleted names. Keep state while resolving partial cleanup.
6. Review a destroy plan for only the selected root:

```bash
terraform -chdir=Examples/01-network-foundation plan -destroy -out=destroy.tfplan
terraform -chdir=Examples/01-network-foundation show destroy.tfplan
terraform -chdir=Examples/01-network-foundation apply destroy.tfplan
```

7. Confirm the intended resources are gone, inspect service-managed resource groups and review Cost Management after billing data catches up. Do not delete Terraform state to hide failed deletions.
8. Keep the separate state bootstrap until every dependent state is migrated or retired and recovery requirements are satisfied. Do not delete the backend while it is storing state for active resources.

No destroy command is included in the validation script or GitHub workflow.

## Production Acceptance Work

Before using these patterns for a client workload, design management groups/subscriptions, ownership, naming, Entra governance, customer policy, RBAC boundaries, network segmentation, centralized DNS, egress inspection, private CI runners, HA/zones, disaster recovery and tested restores. Replace demo SKUs, shared database administration, mutable sample image tags and default image versions with workload-specific choices. Add credential rotation, WAF tuning, application authentication, deployment pipelines, security scanning, monitoring coverage and operational runbooks.

Mocked Terraform tests are useful configuration tests. They cannot prove that a live service is reachable, healthy, secure for a particular threat model, recoverable or compliant with a client's obligations.