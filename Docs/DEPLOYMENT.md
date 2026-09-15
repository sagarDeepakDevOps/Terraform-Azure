# Deployment and Validation

## 1. Start With Local Validation

Use Bash and Terraform 1.9 or later, below 2.0; the tested CLI is 1.15.8. The tests use providers downloaded from the Terraform Registry, but no Azure account is required.

From the project root:

```bash
bash scripts/validate.sh 01-network-foundation
bash scripts/validate.sh
```

The first command checks a single example; the second checks all examples and the state bootstrap. All roots use local state until a backend is deliberately configured. Tests use Terraform's isolated in-memory mock state, not your deployed resource state.

For a deliberate provider upgrade, update the constraint, run `terraform init -upgrade` in the affected roots, review the changed lock files and rerun the tests. The normal validation script uses `-lockfile=readonly`.

## 2. Select an Azure Subscription

Use a sandbox with explicit permission and cost approval. The following commands are for the operator to run for a real deployment, not part of CI validation:

```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
export ARM_SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
export ARM_TENANT_ID="$(az account show --query tenantId --output tsv)"
```

AzureRM 4 requires a subscription ID for authenticated plans/applies. Interactive CLI login is suitable for a local demonstration. For deployment automation, use a dedicated federated/OIDC identity with narrowly scoped permissions. Do not place service-principal secrets, access keys or passwords in HCL, slides or GitHub variables.

A resource contributor may create resources but cannot necessarily grant RBAC roles, assign policies, manage locks or configure billing/security. Use approved roles at the required scopes. Entra group object IDs must already exist for the AKS option. No Entra tenant objects are created here.

## 3. Register Required Resource Providers

Example providers use `resource_provider_registrations = "none"` to avoid silently registering unrelated services. A subscription administrator must pre-register the namespaces required by the selected lab.

| Example | Main required namespaces |
| --- | --- |
| 01 | `Microsoft.Network` |
| 02 | `Microsoft.Network`, `Microsoft.Compute`, `Microsoft.Insights`; `Microsoft.RecoveryServices` for backup |
| 03 | `Microsoft.Network` |
| 04 | `Microsoft.Network`, `Microsoft.Storage`, `Microsoft.ManagedIdentity`, `Microsoft.KeyVault`, `Microsoft.Sql`; selected `Microsoft.DBforPostgreSQL`, `Microsoft.DBforMySQL`, `Microsoft.DocumentDB`, `Microsoft.Cache` |
| 05 | `Microsoft.Network`, `Microsoft.Web`, `Microsoft.App`, `Microsoft.Storage`, `Microsoft.ManagedIdentity`, `Microsoft.OperationalInsights`, `Microsoft.Insights` |
| 06 | `Microsoft.Network`, `Microsoft.App`, `Microsoft.ContainerRegistry`, `Microsoft.ManagedIdentity`, `Microsoft.OperationalInsights`; `Microsoft.ContainerService`, `Microsoft.Compute`, `Microsoft.PolicyInsights` for AKS |
| 07 | `Microsoft.Network`, `Microsoft.Web`, `Microsoft.Cdn` |
| 08 | `Microsoft.Network`, `Microsoft.Storage`, `Microsoft.ServiceBus`, `Microsoft.EventHub`, `Microsoft.EventGrid`, `Microsoft.Logic`, `Microsoft.ManagedIdentity`; `Microsoft.ApiManagement` if selected |
| 09 | `Microsoft.Network`, `Microsoft.Storage`, `Microsoft.DataFactory`; `Microsoft.Synapse`, `Microsoft.Databricks`, `Microsoft.ManagedIdentity` for selected platforms |
| 10 | `Microsoft.Network`, `Microsoft.CognitiveServices`, `Microsoft.Search`, `Microsoft.ManagedIdentity`; `Microsoft.MachineLearningServices`, `Microsoft.Storage`, `Microsoft.KeyVault`, `Microsoft.OperationalInsights`, `Microsoft.Insights` for ML |
| 11 | `Microsoft.Web`, `Microsoft.Insights`, `Microsoft.OperationalInsights`, `Microsoft.Automation`; `Microsoft.Consumption`, `Microsoft.SecurityInsights`, `Microsoft.Security` for selected features |
| State bootstrap | `Microsoft.Storage`; authorization permissions for role grants and lock creation |

For example, an authorized administrator can register networking:

```bash
az provider register --namespace Microsoft.Network --wait
```

Service-managed dependencies can require additional registrations or permissions in a restricted subscription. Check deployment errors and current Microsoft documentation; do not turn on all subscription services indiscriminately.

## 4. Review Inputs and Regional Availability

Each example has a `terraform.tfvars.example` describing non-secret inputs. Create a local variable file from that example and edit it before deployment. Actual `.tfvars` files are ignored by Git. Do not overwrite an existing local file.

- Keep prefixes short and follow module naming constraints. Random suffixes reduce global-name collisions but do not guarantee name availability.
- `eastus2` is a demonstration default, not a guarantee that every service/SKU/model is available there.
- Verify VM quota, VM size, zone support, database capacity, Functions runtime/region and OpenAI model availability.
- Choose non-overlapping address ranges before connecting labs to corporate networks.
- Paid optional paths are explicit booleans or maps. The defaults of a lab can still create billable resources.

For the compute lab, provide only an SSH public key:

```bash
export TF_VAR_ssh_public_key="$(< ~/.ssh/id_ed25519.pub)"
```

Supply Windows passwords, VPN shared keys and PFX material through your approved local/CI secret mechanism. The inputs are sensitive but **ordinary Terraform state and saved plans still retain those values**. The fake values in test files are fixtures, not usable deployment credentials or certificates.

## 5. Plan, Review, Apply

These commands create real resources only at the apply step:

```bash
terraform -chdir=Examples/01-network-foundation init
terraform -chdir=Examples/01-network-foundation validate
terraform -chdir=Examples/01-network-foundation plan -out=demo.tfplan
terraform -chdir=Examples/01-network-foundation show demo.tfplan
terraform -chdir=Examples/01-network-foundation apply demo.tfplan
```

Review the subscription, scope, creates/replacements/deletions, public endpoints, SKUs and prices before applying. A saved-plan apply does not ask for another approval. Do not use `-target` as the normal module deployment workflow or apply all folders with a shell loop.

After applying, run service-specific smoke tests from an authorized network. An output hostname is not evidence that an application was deployed or a backend is healthy. App Service, Functions, AKS, Search and ML still need application/workload configuration as described in their READMEs.

## 6. Private-Network Prerequisites

Azure control-plane operations and service data-plane operations are different. The storage labs configure `features.storage.data_plane_available = false` and use management-plane resource forms. This avoids blocking private account creation on unavailable data-plane endpoints. Storage Tables use AzAPI's ARM API instead of the AzureRM Table resource's shared-key data-plane path.

Reading/writing blobs, mounting Files, querying databases, accessing private Key Vault secrets, invoking private AI services, managing Kubernetes and some Synapse configuration still require:

- A runner/client in the linked VNet or an explicitly connected network.
- Correct private DNS resolution, including links or forwarding for that client network.
- Reachable service ports through routing and NSGs.
- Appropriate data-plane roles or database authentication.

Peering does not automatically link private DNS zones. Public GitHub-hosted runners do not automatically reach a private VNet. Do not fix a private connectivity failure by making all services public.

For Synapse, first deploy with `enable_synapse = true` and `configure_synapse_managed_endpoints = false`. Establish runner access to the private Dev endpoint, then enable the second-stage flag and apply from that connected runner. Approve managed private endpoint requests on the lake before testing data movement. The same storage approval requirement applies to Data Factory's managed endpoints.

## 7. Remote State

Follow [Bootstrap/state/README.md](../Bootstrap/state/README.md). The backend must already exist before Terraform can initialize it; do not make an example depend on creating its own backend.

The [Templates/backend.tf.example](../Templates/backend.tf.example) declares the backend, and [Templates/backend.hcl.example](../Templates/backend.hcl.example) supplies non-secret account/container/key settings. Use a unique state key per example and environment. `use_azuread_auth = true` means backend writers need Storage Blob Data Contributor at the state container scope and a permitted network path.

For OIDC deployment workflows, both backend and provider authentication must be configured. Typical non-secret identity settings are `ARM_CLIENT_ID`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID` and `ARM_USE_OIDC=true`; the workflow needs `id-token: write` and an Entra federated credential with the correct GitHub subject. The included validation workflow intentionally has neither Azure identity nor deployment permissions.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Subscription ID required | Set `ARM_SUBSCRIPTION_ID` and verify the Azure CLI subscription |
| MissingSubscriptionRegistration | Register only the namespace required by the chosen service |
| AuthorizationFailed on a role, policy or lock | The deployer needs the corresponding authorization action at that scope |
| Storage backend 403 | Check backend data role, RBAC propagation, allowed runner IP, DNS and `use_azuread_auth` |
| Private service timeout or public DNS response | Check runner network path and every necessary private DNS VNet link |
| Role assignment exists but initial API access fails | Recheck scope and identity, then allow Azure authorization propagation before retrying |
| VM image/SKU unavailable or quota exceeded | Choose a supported regional SKU or request quota; mock tests cannot detect this |
| Load balancer backend unhealthy | Check cloud-init completion, explicit NAT egress, Nginx and probe/NSG rules |
| APIM 401 | Create/approve a subscription for the Demo product and send its key securely |
| OpenAI deployment rejected | Check actual model name/version, deployment type, regional eligibility and quota |
| Vault deletion/name reuse fails | Purge protection and soft-deletion retention are intentional; retain state or choose a new name |
| Editor shows unexpected module arguments after files were added | Run init and validate for that example and allow the language server to refresh |

See [Docs/SECURITY-AND-COST.md](SECURITY-AND-COST.md) before cleanup.