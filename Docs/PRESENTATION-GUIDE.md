# Client Presentation Guide: Terraform With Azure

Suggested session: 20-30 minutes of explanation plus a 5-minute code walkthrough. The audience should leave understanding how reusable code becomes Azure resources, how changes are reviewed and how cost/security responsibilities remain explicit.

The material below can be used in an existing PowerPoint. It is a slide outline and speaker guide, not a generated PPTX. After publishing the project, use GitHub permalinks to the referenced files so the deck points to a reviewed revision.

## Slide Outline

| Slide | Suggested title | Content and code to show |
| --- | --- | --- |
| 1 | Terraform With Microsoft Azure | Repeatable infrastructure, visible change review, reusable service modules. Position this as a reference project, not a production certification. |
| 2 | From Manual Configuration to Reviewed Code | HCL describes desired state; providers call Azure APIs; state records managed resources. Show the delivery-flow diagram in [Docs/ARCHITECTURE.md](ARCHITECTURE.md). |
| 3 | Project Structure | Show `Modules`, `Examples`, `Bootstrap`, `Docs` and CI. Explain 57 modules, 11 independent scenarios and separate state. |
| 4 | What Is a Module? | Show the short VNet call below, then [Modules/Vnet/main.tf](../Modules/Vnet/main.tf). Inputs configure reusable behavior; outputs connect dependencies. |
| 5 | Azure Networking | VNet, subnet, NSG, route table, peering, Firewall, NAT, Bastion and VPN. Show [Examples/01-network-foundation/main.tf](../Examples/01-network-foundation/main.tf). |
| 6 | Compute and Load Balancing | Two private Linux VMs, Nginx, a health probe and a Standard Load Balancer. Compare VMSS and Windows options using [Examples/02-compute/main.tf](../Examples/02-compute/main.tf). |
| 7 | Storage and Databases | Blob/Files/Queues/Tables, SQL, PostgreSQL, MySQL, Cosmos DB and Managed Redis. Show the engine-selection object and private-data diagram. |
| 8 | Web, Serverless and Containers | Compare App Service, Functions, Container Apps and AKS. Open [Examples/05-web-serverless/main.tf](../Examples/05-web-serverless/main.tf) and [Examples/06-containers/main.tf](../Examples/06-containers/main.tf). |
| 9 | Traffic Delivery and APIs | L4 Load Balancer vs regional L7 Application Gateway vs global Front Door vs DNS Traffic Manager. APIM provides API policy, not the same responsibility as WAF. |
| 10 | Event-Driven Architecture | BlobCreated -> Event Grid -> Service Bus queue; Event Hubs for streams; Logic Apps for workflow. Show [Modules/Messaging/EventGrid/main.tf](../Modules/Messaging/EventGrid/main.tf). |
| 11 | Data and AI Platforms | ADLS/ADF/Synapse/Databricks and AI Services/OpenAI/Search/ML. Distinguish resource provisioning from data ingestion, model availability and application delivery. |
| 12 | Identity and Security | Managed identity plus scoped RBAC, private endpoints plus DNS, HTTPS and state protection. Show [Modules/RoleAssignments/main.tf](../Modules/RoleAssignments/main.tf). |
| 13 | Operations and Cost | Diagnostics, alerts, policy, budgets, backup, Automation, Sentinel and Defender. Budget alerts do not prevent charges; backup is not the same as DR. |
| 14 | Safe Delivery and Next Steps | Explain fmt -> validate -> mock tests -> live plan -> review -> apply -> smoke test -> cleanup. Confirm the pilot scope, costs, permissions and production gaps. |

## Short Excerpt: Reusable Networking

Use this instead of placing an entire resource file on one slide:

```hcl
module "hub" {
  source              = "../../Modules/Vnet"
  name                = "demo-hub-vnet"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = ["10.10.0.0/16"]
  subnets = {
    shared = { address_prefixes = ["10.10.1.0/24"] }
  }
}
```

Speaker note: "The root describes this environment. The module owns the Azure resource implementation. Referring to the resource-group output creates the dependency automatically. The same module is reused for the spoke with different inputs."

## Short Excerpt: Choose Database Services

From [Examples/04-data-services/terraform.tfvars.example](../Examples/04-data-services/terraform.tfvars.example):

```hcl
databases = {
  sql        = true
  postgresql = false
  mysql      = false
  cosmos     = false
  redis      = false
}
```

Speaker note: "All five engines have real modules and tested configuration paths. We choose only the services needed for the demonstration. Enabling all of them changes cost; disabling a previously deployed service can plan its deletion."

## Short Excerpt: Identity Instead of Embedded Keys

From the role-assignment pattern:

```hcl
assignments = {
  blob = {
    scope        = module.storage.id
    role         = "Storage Blob Data Contributor"
    principal_id = module.identity.principal_id
  }
}
```

Speaker note: "The permission is attached to an application identity at a defined resource scope. The application still needs network access. Terraform itself also needs permission to create the role assignment."

## Five-Minute Walkthrough Without Cloud Spend

1. Open [README.md](../README.md) and show the service families, not every file.
2. Open [Examples/01-network-foundation/main.tf](../Examples/01-network-foundation/main.tf); point out hub, spoke and bidirectional peering.
3. Follow `source` into [Modules/Vnet/main.tf](../Modules/Vnet/main.tf), then [Modules/Vnet/subnets/main.tf](../Modules/Vnet/subnets/main.tf).
4. Run the focused check from the project root:

```bash
bash scripts/validate.sh 01-network-foundation
```

5. Show a passing mocked assertion in [Examples/01-network-foundation/tests/network.tftest.hcl](../Examples/01-network-foundation/tests/network.tftest.hcl). State explicitly that no Azure resource was created.
6. Show [Examples/04-data-services/main.tf](../Examples/04-data-services/main.tf) and the private endpoint/DNS map as the next level of composition.

For a live browser demonstration, deploy the compute or Container Apps scenario in an approved sandbox before the meeting, verify it, and clean it up afterward. Do not wait for Firewall, VPN, AKS or APIM provisioning during a short presentation.

## Client Questions and Accurate Answers

**Does Terraform replace Azure?** No. Terraform calls Azure APIs to manage resources. Azure still provides and operates the services.

**Does this create every Azure service?** No. It implements the major service families listed in the catalog. Specialized products and enterprise landing-zone decisions are explicit extensions.

**Can the same code serve development and production?** Reusable modules can, but environment inputs, state, permissions, availability, security and approval policies must be isolated. Changing only an environment tag is not production hardening.

**Are private endpoints enough for security?** No. Private DNS, routing, access control, identity, authorization, encryption, monitoring and application behavior still matter.

**Are passwords protected by Terraform's sensitive flag?** The flag redacts normal output. State and saved plans can still contain the actual values and must be protected.

**Can a budget stop overspending?** Azure budgets notify. They do not automatically shut down all resources or impose a hard spending ceiling.

**Do passing tests prove Azure will deploy it?** They prove the tested Terraform contracts and schema checks passed. A real pilot is still needed for permissions, quotas, region/SKU constraints, private connectivity and runtime behavior.

**Is this production-ready as-is?** No. It is teaching/reference code. Use the production acceptance checklist in [Docs/SECURITY-AND-COST.md](SECURITY-AND-COST.md) to define the customer's pilot and implementation work.