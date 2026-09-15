# Implemented Service Catalog

The project contains 57 module directories. A module count is not a count of Azure products: some modules compose multiple resource types, while others are reusable supporting resources such as RBAC or DNS links. Every module is referenced by at least one example.

## Networking and Delivery

| Module source | Implemented resources and behavior | Main example / boundary |
| --- | --- | --- |
| [Modules/ResourceGroups/main.tf](../Modules/ResourceGroups/main.tf) | Resource group, location and tags | All examples |
| [Modules/Vnet/main.tf](../Modules/Vnet/main.tf) | VNet and child subnet composition | 01; private address space |
| [Modules/Vnet/subnets/main.tf](../Modules/Vnet/subnets/main.tf) | Subnets, delegation, service endpoints, private endpoint policies | Nested inside Vnet; implicit outbound access disabled |
| [Modules/Vnet/NSG/main.tf](../Modules/Vnet/NSG/main.tf) | Security rules and subnet associations | 01, 02, 03; do not attach to GatewaySubnet or AzureFirewallSubnet |
| [Modules/Vnet/routeTables/main.tf](../Modules/Vnet/routeTables/main.tf) | UDRs, BGP propagation setting and subnet associations | 01 has a discard route; 03 routes egress to its real firewall |
| [Modules/Vnet/Peering/main.tf](../Modules/Vnet/Peering/main.tf) | Both peering directions, forwarded traffic, optional gateway transit | 01, 03; peering is not transitive |
| [Modules/Vnet/Firewalls/main.tf](../Modules/Vnet/Firewalls/main.tf) | Standard Firewall, public IP, policy, DNS proxy and FQDN rules | 03; significant hourly cost |
| [Modules/Vnet/NATGateway/main.tf](../Modules/Vnet/NATGateway/main.tf) | Standard NAT Gateway, static public IP and subnet associations | 02, 05, 06; explicit outbound only |
| [Modules/Vnet/Bastion/main.tf](../Modules/Vnet/Bastion/main.tf) | Standard Bastion, tunneling and dedicated public IP | Optional in 03; target VM permissions/NSGs still apply |
| [Modules/Vnet/VPNGateway/main.tf](../Modules/Vnet/VPNGateway/main.tf) | VpnGw1AZ Generation1, optional local gateway and IKEv2 S2S connection | Optional in 03; remote VPN device is not configured |
| [Modules/Vnet/PrivateDNS/main.tf](../Modules/Vnet/PrivateDNS/main.tf) | Private zone and explicit VNet links | Every private PaaS example |
| [Modules/Vnet/PrivateEndpoints/main.tf](../Modules/Vnet/PrivateEndpoints/main.tf) | Private service connection and DNS zone group | Does not itself disable the service's public endpoint |
| [Modules/LoadBalancers/main.tf](../Modules/LoadBalancers/main.tf) | Standard public L4 LB, backend pool, NIC membership, HTTP probe and TCP rule | 02; HTTP-only sample, no TLS termination |
| [Modules/ApplicationGateway/main.tf](../Modules/ApplicationGateway/main.tf) | WAF_v2, HTTPS listener, TLS policy, HTTPS backend, probe and autoscaling | Optional in 07; real PFX and healthy backend required |
| [Modules/FrontDoor/main.tf](../Modules/FrontDoor/main.tf) | Premium profile, endpoint, origin, HTTPS route and managed WAF | 07; restricted App Service origin |
| [Modules/TrafficManager/main.tf](../Modules/TrafficManager/main.tf) | Priority-based DNS profile and HTTPS-monitored external endpoints | Optional in 07; supply two independently hosted applications |
| [Modules/DNS/main.tf](../Modules/DNS/main.tf) | Public DNS zone, A records and CNAME records | 07; domain registration, delegation and TLS binding are separate |

## Compute and Application Platforms

| Module source | Implemented resources and behavior | Main example / boundary |
| --- | --- | --- |
| [Modules/VMS/Linux/main.tf](../Modules/VMS/Linux/main.tf) | Ubuntu Gen2 VM, private NIC, SSH-only auth, managed identity, boot diagnostics | 02 installs Nginx with cloud-init |
| [Modules/VMS/Windows/main.tf](../Modules/VMS/Windows/main.tf) | Windows Server 2022 VM, private NIC, identity and boot diagnostics | Optional in 02; no public RDP |
| [Modules/VMScaleSets/main.tf](../Modules/VMScaleSets/main.tf) | Linux VMSS, LB attachment and CPU scale-in/scale-out rules | Optional in 02; manual image upgrade policy |
| [Modules/AppService/main.tf](../Modules/AppService/main.tf) | Linux plan and Web App, Node 22 runtime, HTTPS, identity, optional VNet and origin restrictions | 05, 07, 11; application package is not included |
| [Modules/Functions/main.tf](../Modules/Functions/main.tf) | FC1 Flex Consumption Function App, Node 22, identity-backed storage and VNet integration | 05; function package is a separate deployment |
| [Modules/ContainerRegistry/main.tf](../Modules/ContainerRegistry/main.tf) | ACR without shared admin credentials | 06; Basic authenticated public endpoint by default |
| [Modules/ContainerApps/main.tf](../Modules/ContainerApps/main.tf) | Workload-profile environment, sample container, health checks, HTTPS and HTTP scaling | 06 starts a public sample image; ACR is ready for later image publishing |
| [Modules/AKS/main.tf](../Modules/AKS/main.tf) | Private AKS, CNI overlay/Cilium, explicit identities, AcrPull, Entra RBAC, autoscaling, logs, CSI secrets provider | Optional in 06; no Kubernetes workloads or public API |
| [Modules/APIManagement/main.tf](../Modules/APIManagement/main.tf) | Developer APIM, HTTPS API/operation/product, subscription requirement and rate-limit/response policy | Optional in 08; no production SLA; approve a subscription before calling |
| [Modules/Automation/main.tf](../Modules/Automation/main.tf) | Automation account, managed identity and credential-free PowerShell runbook | 11; no automatic schedule |

## Storage and Databases

| Module source | Implemented resources and behavior | Main example / boundary |
| --- | --- | --- |
| [Modules/Storage/main.tf](../Modules/Storage/main.tf) | StorageV2, private Blob containers, SMB Files shares, Queues, ARM-created Tables, optional ADLS Gen2 and lifecycle policy | 04; Files identity/domain setup is required before SMB mounting |
| [Modules/Databases/SQL/main.tf](../Modules/Databases/SQL/main.tf) | Private Azure SQL logical server and Basic database, TLS, short-term retention | Default in 04; SQL authentication is a demo choice |
| [Modules/Databases/PostgreSQL/main.tf](../Modules/Databases/PostgreSQL/main.tf) | PostgreSQL 16 Flexible Server and app database | Optional in 04; delegated subnet and private DNS, no HA |
| [Modules/Databases/MySQL/main.tf](../Modules/Databases/MySQL/main.tf) | MySQL Flexible Server, app database and required secure transport | Optional in 04; `8.0.21` is the Azure API version selector, not a claim about the live patch level |
| [Modules/Databases/CosmosDB/main.tf](../Modules/Databases/CosmosDB/main.tf) | Serverless NoSQL account, database, partitioned container and data RBAC | Optional in 04; one region, Entra auth |
| [Modules/Databases/ManagedRedis/main.tf](../Modules/Databases/ManagedRedis/main.tf) | Azure Managed Redis and encrypted default database | Optional in 04; small non-HA demo SKU, access keys remain sensitive in state |
| [Modules/Backup/main.tf](../Modules/Backup/main.tf) | Recovery Services vault, daily VM policy and protected VM bindings | Optional in 02; backup is not cross-region disaster recovery |

## Integration and Analytics

| Module source | Implemented resources and behavior | Main example / boundary |
| --- | --- | --- |
| [Modules/Messaging/ServiceBus/main.tf](../Modules/Messaging/ServiceBus/main.tf) | Standard namespace, duplicate-detecting queue, topic, subscription and dead-letter settings | 08; Entra-authenticated public endpoint; private networking needs Premium |
| [Modules/Messaging/EventHubs/main.tf](../Modules/Messaging/EventHubs/main.tf) | Standard namespace, bounded auto-inflate, partitioned stream and consumer group | 08; identity-based public access; no producer/consumer program |
| [Modules/Messaging/EventGrid/main.tf](../Modules/Messaging/EventGrid/main.tf) | Storage system topic, BlobCreated filter and identity-based queue delivery | 08; upload a blob from an authorized private-network client to exercise it |
| [Modules/LogicApps/main.tf](../Modules/LogicApps/main.tf) | Daily recurrence trigger and Compose action | 08; disabled until explicitly enabled |
| [Modules/Analytics/DataFactory/main.tf](../Modules/Analytics/DataFactory/main.tf) | Managed-VNet ADF, integration runtime, identity-backed lake link, managed endpoints and Wait pipeline | 09; approve endpoints before lake data movement |
| [Modules/Analytics/Synapse/main.tf](../Modules/Analytics/Synapse/main.tf) | Private workspace, lake association and storage role | Optional in 09; no Spark or dedicated SQL pool; managed endpoints are a second stage |
| [Modules/Analytics/Databricks/main.tf](../Modules/Analytics/Databricks/main.tf) | VNet-injected Premium workspace, no public node IPs, access connector and lake role | Optional in 09; clusters, jobs and Unity Catalog are separate |

## AI and Machine Learning

| Module source | Implemented resources and behavior | Main example / boundary |
| --- | --- | --- |
| [Modules/AI/CognitiveServices/main.tf](../Modules/AI/CognitiveServices/main.tf) | Private multi-service AI account, custom subdomain and identity | 10; individual capabilities can have eligibility restrictions |
| [Modules/AI/OpenAI/main.tf](../Modules/AI/OpenAI/main.tf) | Private Azure OpenAI account and explicit model/version/SKU deployment map | Optional in 10; model lifecycle, quota and region checks are mandatory |
| [Modules/AI/Search/main.tf](../Modules/AI/Search/main.tf) | Private Basic Search with Entra authentication and identity | 10; no indexes, documents, indexers or end-to-end RAG application |
| [Modules/AI/MachineLearning/main.tf](../Modules/AI/MachineLearning/main.tf) | Private ML workspace with identity-based storage and managed-network configuration | Optional in 10; provision/approve outbound network and compute before training |

## Identity, Observability and Governance

| Module source | Implemented resources and behavior | Main example / boundary |
| --- | --- | --- |
| [Modules/Identity/main.tf](../Modules/Identity/main.tf) | User-assigned managed identity | Not an Entra user/group/app-registration manager |
| [Modules/RoleAssignments/main.tf](../Modules/RoleAssignments/main.tf) | Explicit scoped role assignments | Deployer requires role-assignment permissions |
| [Modules/KeyVault/main.tf](../Modules/KeyVault/main.tf) | Private RBAC vault, purge protection and soft deletion | 04, 10; no secrets seeded from a public runner |
| [Modules/Monitoring/LogAnalytics/main.tf](../Modules/Monitoring/LogAnalytics/main.tf) | Workspace, retention and ingestion quota | 05, 06, 10, 11 |
| [Modules/Monitoring/ApplicationInsights/main.tf](../Modules/Monitoring/ApplicationInsights/main.tf) | Workspace-backed application telemetry resource | 05, 10; application instrumentation is still required |
| [Modules/Monitoring/DiagnosticSettings/main.tf](../Modules/Monitoring/DiagnosticSettings/main.tf) | Platform log/metric forwarding | 11; select categories supported by the target service |
| [Modules/Monitoring/Alerts/main.tf](../Modules/Monitoring/Alerts/main.tf) | Metric alert and email action group | 11; monitor the configured mailbox |
| [Modules/Governance/Policy/main.tf](../Modules/Governance/Policy/main.tf) | Built-in Allowed locations policy at resource-group scope | 11; DoNotEnforce by default |
| [Modules/Governance/Budget/main.tf](../Modules/Governance/Budget/main.tf) | Actual and forecast monthly budget notifications | Optional in 11; notifications do not stop spending |
| [Modules/Governance/Locks/main.tf](../Modules/Governance/Locks/main.tf) | CanNotDelete management lock | Optional in 11 and enabled for bootstrap storage; not a backup |
| [Modules/Security/Sentinel/main.tf](../Modules/Security/Sentinel/main.tf) | Sentinel workspace onboarding | Optional in 11; connectors, detection rules and SOC processes are separate |
| [Modules/Security/Defender/main.tf](../Modules/Security/Defender/main.tf) | Subscription-wide paid Servers P1 and Defender for Storage plans | Optional in 11; import/reconcile existing settings, obtain owner approval |

## Scope Boundary

These are the major service families typically used in an Azure Terraform introduction. Specialized extensions are intentionally **not implemented**: ExpressRoute/Virtual WAN, Azure Site Recovery replication, Azure Virtual Desktop, Azure Arc, Azure NetApp Files, SQL Managed Instance, dedicated Synapse compute, IoT Hub/DPS, HPC/Batch, SAP, Microsoft Fabric capacity, Purview governance, Entra tenant objects and management-group landing zones. They require additional commercial, tenant, network, quota or workload decisions. Do not present a directory or a future-extension idea as deployed coverage.

Use [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/) and [Azure Architecture Center](https://learn.microsoft.com/azure/architecture/) to design those customer-specific additions. The examples here are intentionally readable teaching code, not a substitute for a production design review.