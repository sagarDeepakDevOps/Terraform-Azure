# Terraform on Azure: Modular Reference Project

A GitHub-ready teaching project for explaining Azure infrastructure as code to a client. It contains **57 reusable modules**, **11 independently deployable examples**, a separate remote-state bootstrap, and **23 credential-free mocked test runs**.

Start with [Docs/PRESENTATION-GUIDE.md](Docs/PRESENTATION-GUIDE.md) for the client session and [Docs/SERVICE-CATALOG.md](Docs/SERVICE-CATALOG.md) for the complete implemented service list.

**This is a reference and demonstration project, not a production landing zone.** It covers the main Azure infrastructure and application-platform families, not literally every product or SKU in Azure. Paid services, private networking, regional quotas, application deployment and customer-specific security decisions still need review. Nothing is deployed just by opening or testing the repository.

## Project Structure

```text
Terraform-Azure/
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

Each module has resource definitions, typed inputs with descriptions, outputs, and a provider compatibility declaration. Each example has its own provider configuration, input sample, outputs, tests, dependency lock file and README. There is deliberately **no deploy-everything root configuration**.

## Choose an Example

| Example | Default scenario | Optional additions |
| --- | --- | --- |
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
bash scripts/validate.sh 01-network-foundation
```

Check the entire project:

```bash
bash scripts/validate.sh
```

The script checks formatting, initializes without a remote backend, validates, and runs mocked plans. All test providers are mocked; these checks do not authenticate to Azure or create resources. They do not prove regional SKU availability, permissions, network reachability, quotas or successful live deployment.

## Deploy Deliberately

Read [Docs/DEPLOYMENT.md](Docs/DEPLOYMENT.md) and [Docs/SECURITY-AND-COST.md](Docs/SECURITY-AND-COST.md) before using a real subscription. Start with the network foundation. Do not apply every example for a presentation.

After Azure login, subscription selection, provider registration, input review and cost approval:

```bash
terraform -chdir=Examples/01-network-foundation init
terraform -chdir=Examples/01-network-foundation plan -out=demo.tfplan
terraform -chdir=Examples/01-network-foundation apply demo.tfplan
```

Applying a saved plan performs its approved changes without another confirmation. Do not run the final command until the plan has been reviewed. Plans and state can contain secrets and must not be published.

## A Small Code Example for Slides

This is the module interface used by the networking examples:

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

Explain the resource group output dependency, the reusable module source, and the map that creates nested subnets. Open [Modules/Vnet/main.tf](Modules/Vnet/main.tf) to show the implementation.

## GitHub and Presentation Handoff

Publish this directory as the root of its own repository to use the included workflow unchanged. While it remains a subdirectory of a larger repository, GitHub will not discover its nested workflow automatically. Do not publish local provider downloads, state, saved plans, actual variable files, keys or credentials. The project ignore file excludes these; provider lock files and input examples remain included.

No remote repository is assumed or configured. After publishing, use GitHub permalinks to reviewed code in the PowerPoint so slide links remain stable across later changes.

## Documentation

- [Docs/SERVICE-CATALOG.md](Docs/SERVICE-CATALOG.md): every implemented module and its demo boundary.
- [Docs/ARCHITECTURE.md](Docs/ARCHITECTURE.md): GitHub-renderable Mermaid diagrams and network flow explanations.
- [Docs/PRESENTATION-GUIDE.md](Docs/PRESENTATION-GUIDE.md): slide outline, short excerpts, speaker notes and client questions.
- [Docs/DEPLOYMENT.md](Docs/DEPLOYMENT.md): authentication, registrations, inputs, state and troubleshooting.
- [Docs/SECURITY-AND-COST.md](Docs/SECURITY-AND-COST.md): security choices, cost drivers, cleanup and production gaps.
- [Modules/README.md](Modules/README.md): module contracts and how to extend the project.
- [Bootstrap/state/README.md](Bootstrap/state/README.md): independent remote-state bootstrap.

## Verification Status

All 12 roots passed `terraform validate`; all 23 mocked test runs passed with the versions above. Recursive formatting and Bash syntax checks passed. No live Azure plan, apply, destroy, application smoke test or cloud security certification was performed. A client-specific pilot deployment remains a separate acceptance step.# Terraform-Azure
