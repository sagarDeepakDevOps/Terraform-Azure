# Terraform on Azure: Modular Reference Project

A GitHub-ready teaching project for explaining Azure infrastructure as code to a client. It contains **57 reusable modules**, a **three-module root starter**, **11 independently deployable examples**, a separate remote-state bootstrap, and **25 credential-free mocked test runs**.

Start with [main.tf](main.tf) for a short, commented module walkthrough and [Docs/SERVICE-CATALOG.md](Docs/SERVICE-CATALOG.md) for the complete implemented service list.

**This is a reference and demonstration project, not a production landing zone.** It covers the main Azure infrastructure and application-platform families, not literally every product or SKU in Azure. Paid services, private networking, regional quotas, application deployment and customer-specific security decisions still need review. Nothing is deployed just by opening or testing the repository.

## Project Structure

```text
Terraform-Azure/
|-- main.tf
|-- providers.tf
|-- versions.tf
|-- variables.tf
|-- outputs.tf
|-- terraform.tfvars.example
|-- .terraform.lock.hcl
|-- tests/root.tftest.hcl
|-- Modules/
|   |-- ResourceGroups/
|   |-- VMS/
|   |   |-- Linux/
|   |   `-- Windows/
|   |-- VMScaleSets/
|   |-- LoadBalancers/
|   |-- Vnet/
|   |   |-- subnets/
|   |   |-- routeTables/
|   |   |-- NSG/
|   |   |-- Firewalls/
|   |   |-- Peering/
|   |   |-- NATGateway/
|   |   |-- Bastion/
|   |   |-- VPNGateway/
|   |   |-- PrivateDNS/
|   |   `-- PrivateEndpoints/
|   |-- ApplicationGateway/
|   |-- FrontDoor/
|   |-- TrafficManager/
|   |-- DNS/
|   |-- Storage/
|   |-- Databases/
|   |   |-- SQL/
|   |   |-- PostgreSQL/
|   |   |-- MySQL/
|   |   |-- CosmosDB/
|   |   `-- ManagedRedis/
|   |-- AppService/
|   |-- Functions/
|   |-- ContainerRegistry/
|   |-- ContainerApps/
|   |-- AKS/
|   |-- APIManagement/
|   |-- Messaging/
|   |   |-- ServiceBus/
|   |   |-- EventHubs/
|   |   `-- EventGrid/
|   |-- LogicApps/
|   |-- Analytics/
|   |   |-- DataFactory/
|   |   |-- Synapse/
|   |   `-- Databricks/
|   |-- AI/
|   |   |-- CognitiveServices/
|   |   |-- OpenAI/
|   |   |-- Search/
|   |   `-- MachineLearning/
|   |-- Identity/
|   |-- RoleAssignments/
|   |-- KeyVault/
|   |-- Monitoring/
|   |   |-- LogAnalytics/
|   |   |-- ApplicationInsights/
|   |   |-- DiagnosticSettings/
|   |   `-- Alerts/
|   |-- Governance/
|   |   |-- Policy/
|   |   |-- Budget/
|   |   `-- Locks/
|   |-- Security/
|   |   |-- Sentinel/
|   |   `-- Defender/
|   |-- Backup/
|   `-- Automation/
|-- Examples/
|   |-- 01-network-foundation/
|   |-- 02-compute/
|   |-- 03-secure-hub/
|   |-- 04-data-services/
|   |-- 05-web-serverless/
|   |-- 06-containers/
|   |-- 07-edge-delivery/
|   |-- 08-integration/
|   |-- 09-analytics/
|   |-- 10-ai-ml/
|   `-- 11-operations-governance/
|-- Bootstrap/state/
|-- Templates/
|-- Docs/
|-- scripts/validate.sh
`-- .github/workflows/terraform-checks.yml
```

The case-sensitive names follow the requested `Modules/VMS`, `Modules/LoadBalancers`, and nested `Modules/Vnet` structure. The VNet module creates its child subnets. Other network modules live under Vnet but are composed explicitly by each example; creating a VNet never silently creates a paid firewall or gateway.

Each module has resource definitions, typed inputs with descriptions, outputs, and a provider compatibility declaration. Each example has its own provider configuration, input sample, outputs, tests, dependency lock file and README. The repository root now contains a small runnable starter, not a **deploy-everything configuration**.

## Root Starter Example

Open [main.tf](main.tf) to see three real module calls:

1. **ResourceGroups** creates a dedicated resource group.
2. **Vnet** uses that group's outputs to create a VNet and a nested `workload` subnet.
3. **NSG** uses the subnet output to attach an internal-HTTPS allow rule and an explicit inbound deny.

The default address space is `10.120.0.0/16`, with subnet `10.120.1.0/24` and resource prefix `aztfroot`. No VM, public IP, NAT gateway, firewall, database or application is created. Terraform loads only this directory's configuration; it does not automatically deploy the numbered examples or every module beneath it.

| Root file | Responsibility |
| --- | --- |
| [main.tf](main.tf) | Three commented module calls and their dependencies |
| [providers.tf](providers.tf) | AzureRM authentication context and explicit registration behavior |
| [versions.tf](versions.tf) | Compatible Terraform and AzureRM versions |
| [variables.tf](variables.tf) | Prefix, region, VNet/subnet CIDRs and tags |
| [terraform.tfvars.example](terraform.tfvars.example) | Non-secret sample overrides; the `.example` suffix is not loaded automatically |
| [outputs.tf](outputs.tf) | Created group/network names, subnet IDs and NSG ID |
| [tests/root.tftest.hcl](tests/root.tftest.hcl) | Credential-free tests of default and customized module inputs |
| [.terraform.lock.hcl](.terraform.lock.hcl) | Exact root provider selection and checksums; retain in Git |

Keep the root starter's state independent from the numbered examples and state bootstrap. If using a remote backend, give this root its own key, for example `demo/root-starter.tfstate`. Refer to [Templates/backend.tf.example](Templates/backend.tf.example) and [Templates/backend.hcl.example](Templates/backend.hcl.example) for the optional backend setup; the starter does not require an existing backend for local validation.

To use another service later, select its exact module directory, read its input descriptions, add a `module` call with `source = "./Modules/YourSelectedService"`, and pass the required values or other module outputs. The detailed numbered examples demonstrate those service-specific prerequisites. Adding a module to this root can add costs and affect its state, so review the resulting plan.

## Choose an Example

| Example | Default scenario | Optional additions |
| --- | --- | --- |
| [main.tf](main.tf) | Root starter: resource group, one VNet/subnet and an attached NSG | Extend by explicitly calling another service module |
| [Examples/01-network-foundation/README.md](Examples/01-network-foundation/README.md) | Hub/spoke VNets, subnets, peering, NSG, route table, private DNS | No paid gateway or VM |
| [Examples/02-compute/README.md](Examples/02-compute/README.md) | Two private Linux web VMs, public Standard Load Balancer, NAT | Windows, autoscaling VMSS, VM Backup |
| [Examples/03-secure-hub/README.md](Examples/03-secure-hub/README.md) | Standard Azure Firewall, policy, routed spoke | Standard Bastion, VPN Gateway, site-to-site connection |
| [Examples/04-data-services/README.md](Examples/04-data-services/README.md) | Blob/Files/Queues/Tables, Key Vault, identity, private SQL | PostgreSQL, MySQL, Cosmos DB, Managed Redis |
| [Examples/05-web-serverless/README.md](Examples/05-web-serverless/README.md) | App Service, Flex Functions, private storage, monitoring, NAT | Deploy application code separately |
| [Examples/06-containers/README.md](Examples/06-containers/README.md) | ACR, runnable Container App, identities, NAT, logs | Private AKS with Entra administration |
| [Examples/07-edge-delivery/README.md](Examples/07-edge-delivery/README.md) | Front Door Premium/WAF, restricted Web App origin, public DNS | HTTPS Application Gateway/WAF, Traffic Manager |
| [Examples/08-integration/README.md](Examples/08-integration/README.md) | Service Bus, Event Hubs, Storage-to-Event-Grid delivery, disabled Logic App | API Management, scheduled workflow execution |
| [Examples/09-analytics/README.md](Examples/09-analytics/README.md) | ADLS Gen2, Data Factory, managed endpoints, Wait pipeline | Synapse and Databricks workspaces |
| [Examples/10-ai-ml/README.md](Examples/10-ai-ml/README.md) | Private AI Services and AI Search | OpenAI/model deployments, Machine Learning workspace |
| [Examples/11-operations-governance/README.md](Examples/11-operations-governance/README.md) | Web App diagnostics, alerts, non-enforced location policy, Automation | Budget, lock, Sentinel, subscription-wide Defender |

Numbers are a learning order, **not a deployment dependency**. Each example creates its own resources and state. Applying one does not connect it to another.

## Try It Without an Azure Account

Use Terraform 1.9 or newer, below 2.0. The local and CI verification baseline is Terraform **1.15.8**, AzureRM **4.81.0**, AzAPI **2.12.0**, and Random **3.9.1**. Provider downloads require Internet access on first initialization. Keep the lock files in Git.

From this project directory:

```bash
bash scripts/validate.sh root
```

Use a numbered example name instead of `root` to check that example, or `state` for the backend bootstrap. Check all 13 deployment roots:

```bash
bash scripts/validate.sh
```

The script checks formatting, initializes without a remote backend, validates, and runs mocked plans. All test providers are mocked; these checks do not authenticate to Azure or create resources. They do not prove regional SKU availability, permissions, network reachability, quotas or successful live deployment.

## Deploy Deliberately

Read [Docs/DEPLOYMENT.md](Docs/DEPLOYMENT.md) and [Docs/SECURITY-AND-COST.md](Docs/SECURITY-AND-COST.md) before using a real subscription. Start with the small root starter or the numbered network foundation. Do not apply every example for a presentation.

After Azure login, subscription selection, provider registration, input review and cost approval:

```bash
terraform init
terraform plan -out=demo.tfplan
terraform apply demo.tfplan
```

Run these commands from the repository root for the three-module starter. To deploy a numbered example instead, use its directory or Terraform's `-chdir=Examples/<name>` option. Applying a saved plan performs its approved changes without another confirmation. Do not run the final command until the plan has been reviewed. Plans and state can contain secrets and must not be published.

## A Small Code Example for Slides

This excerpt from the root starter demonstrates passing one module's outputs into another:

```hcl
module "network" {
  source              = "./Modules/Vnet"
  name                = "${var.prefix}-vnet"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = [var.vnet_cidr]
  subnets = {
    workload = { address_prefixes = [var.workload_subnet_cidr] }
  }
}
```

Explain the resource group output dependency, the reusable module source, and the map that creates nested subnets. Open [Modules/Vnet/main.tf](Modules/Vnet/main.tf) to show the implementation.

## GitHub and Presentation Handoff

Publish this directory as the root of its own repository to use the included workflow unchanged. While it remains a subdirectory of a larger repository, GitHub will not discover its nested workflow automatically. Do not publish local provider downloads, state, saved plans, actual variable files, keys or credentials. The project ignore file excludes these; provider lock files and input examples remain included.

No remote repository is assumed or configured. After publishing, use GitHub permalinks to reviewed code in the PowerPoint so slide links remain stable across later changes.

## Documentation

- [Docs/SERVICE-CATALOG.md](Docs/SERVICE-CATALOG.md): every implemented module and its demo boundary.
- [Docs/ARCHITECTURE.md](Docs/ARCHITECTURE.md): GitHub-renderable Mermaid diagrams and network flow explanations.
- [Docs/DEPLOYMENT.md](Docs/DEPLOYMENT.md): authentication, registrations, inputs, state and troubleshooting.
- [Docs/SECURITY-AND-COST.md](Docs/SECURITY-AND-COST.md): security choices, cost drivers, cleanup and production gaps.
- [Modules/README.md](Modules/README.md): module contracts and how to extend the project.
- [Bootstrap/state/README.md](Bootstrap/state/README.md): independent remote-state bootstrap.

## Verification Status

All 13 roots, including the repository-root starter, passed `terraform validate`; all 25 mocked test runs passed with the versions above. Recursive formatting and Bash syntax checks passed. No live Azure plan, apply, destroy, application smoke test or cloud security certification was performed. A client-specific pilot deployment remains a separate acceptance step.


## Questions and Answers

**Does Terraform replace Azure?** No. Terraform calls Azure APIs to manage resources. Azure still provides and operates the services.

**Does this create every Azure service?** No. It implements the major service families listed in the catalog. Specialized products and enterprise landing-zone decisions are explicit extensions.

**Can the same code serve development and production?** Reusable modules can, but environment inputs, state, permissions, availability, security and approval policies must be isolated. Changing only an environment tag is not production hardening.

**Are private endpoints enough for security?** No. Private DNS, routing, access control, identity, authorization, encryption, monitoring and application behavior still matter.

**Are passwords protected by Terraform's sensitive flag?** The flag redacts normal output. State and saved plans can still contain the actual values and must be protected.

**Can a budget stop overspending?** Azure budgets notify. They do not automatically shut down all resources or impose a hard spending ceiling.

**Do passing tests prove Azure will deploy it?** They prove the tested Terraform contracts and schema checks passed. A real pilot is still needed for permissions, quotas, region/SKU constraints, private connectivity and runtime behavior.

**Is this production-ready as-is?** No. It is teaching/reference code. Use the production acceptance checklist in [Docs/SECURITY-AND-COST.md](Docs/SECURITY-AND-COST.md) to define the customer's pilot and implementation work.
