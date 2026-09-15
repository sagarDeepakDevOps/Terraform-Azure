# Architecture and Dependency Flows

These diagrams correspond to individual examples. They are not a claim that applying every directory creates one integrated production platform. GitHub renders the Mermaid blocks directly.

## Terraform Delivery Flow

```mermaid
flowchart LR
    Author[Engineer changes HCL] --> PR[GitHub pull request]
    PR --> Checks[Format, validate, mocked tests]
    Checks --> Review[Code and security review]
    Review --> Plan[Authenticated Terraform plan]
    Plan --> Approval[Cost and deployment approval]
    Approval --> Apply[Apply reviewed plan]
    Apply --> ARM[Azure Resource Manager APIs]
    Apply <--> State[Entra-protected Blob state and lease locking]
```

The included GitHub workflow implements the credential-free checks. The authenticated plan and approval/apply stages are shown as a production delivery pattern, not as an enabled deployment workflow. Terraform state and the provider dependency lock file serve different purposes.

## Network Foundation: Example 01

```mermaid
flowchart LR
    Hub[Hub VNet 10.10.0.0/16] <-->|Two peering resources| Spoke[Spoke VNet 10.20.0.0/16]
    Hub --> Shared[Shared subnet]
    Spoke --> Web[Web subnet]
    Spoke --> App[App subnet]
    NSG[NSG: hub HTTPS, then deny] --> Web
    Route[UDR: discard documentation range] --> Web
    DNS[Private DNS zone] --- Hub
    DNS --- Spoke
```

The web NSG permits the demonstrated HTTPS path and denies other inbound traffic, overriding broad default VNet rules on that subnet. The app subnet is only a topology example, not a complete tier-segmentation policy. Peering is bidirectional but not transitive. No Internet gateway, VM or firewall is hidden in this lab.

## Compute: Example 02

```mermaid
flowchart LR
    Browser[Browser: HTTP demo] --> LB[Standard Load Balancer]
    LB --> VM1[Private Linux web01]
    LB --> VM2[Private Linux web02]
    LB -. Optional backend .-> VMSS[Linux VM Scale Set]
    VM1 --> NAT[NAT Gateway]
    VM2 --> NAT
    VMSS --> NAT
    NAT --> Packages[Package repositories]
    VM1 -. Optional protection .-> Backup[Recovery Services vault]
    VM2 -. Optional protection .-> Backup
```

NSG rules allow the web port and the Azure load-balancer health probe. No public SSH/RDP rule is created. NAT provides explicit egress for cloud-init and patch downloads; a load-balancer inbound rule is not treated as an outbound design. HTTP is intentionally limited to non-sensitive sample content.

## Secure Hub: Example 03

```mermaid
flowchart LR
    OnPrem[Remote VPN device] -. Optional IKEv2 tunnel .-> VPN[Hub VPN Gateway]
    Admin[Administrator] -. Optional .-> Bastion[Hub Bastion]
    VPN --- Hub[Hub VNet]
    Bastion --- Hub
    Hub <-->|Forwarded traffic and optional transit| Spoke[Spoke workload subnet]
    Spoke -->|Default UDR| Firewall[Hub Azure Firewall]
    Firewall -->|Approved FQDNs only| Internet[Internet destinations]
```

The firewall is actually created before its IP is used as the UDR next hop. Reserved appliance subnets retain their Azure-required names. The spoke NSG permits administration from the Bastion subnet; no workload VM is included in this topology-only lab. VPN transit is enabled only when the hub gateway exists. A remote gateway and its route configuration are outside Terraform's Azure resources.

## Private Data: Example 04

```mermaid
flowchart LR
    Client[Authorized VNet-connected client] --> DNS[Linked private DNS zones]
    Client --> PE[Private endpoint subnet]
    PE --> Storage[Blob, Files, Queues, Tables]
    PE --> Vault[Key Vault]
    PE --> SQL[Azure SQL]
    PE -. Optional .-> Cosmos[Cosmos DB]
    PE -. Optional .-> Redis[Managed Redis]
    Client -. Delegated subnet .-> PG[PostgreSQL Flexible Server]
    Client -. Delegated subnet .-> MySQL[MySQL Flexible Server]
    Identity[Application managed identity] --> RBAC[Scoped data roles]
```

Network reachability and authorization are separate. A private endpoint does not grant access, and an RBAC role does not provide a network route. PostgreSQL and MySQL use dedicated delegated subnets in this design, not private endpoints. The example creates the data network but not a laptop VPN or jump VM.

## Web Delivery: Example 07

```mermaid
flowchart LR
    User[HTTPS client] --> FD[Front Door Premium]
    WAF[Managed WAF in Prevention] --> FD
    FD -->|HTTPS with matching origin host| Web[App Service origin]
    Restriction[Front Door service tag and X-Azure-FDID check] --> Web
```

Application Gateway and Traffic Manager are independent optional comparisons, not extra hops automatically inserted into this path. Front Door proxies HTTP traffic; Traffic Manager returns DNS answers; a Standard Load Balancer forwards layer-4 traffic.

## Events: Example 08

```mermaid
flowchart LR
    Uploader[Authorized private-network uploader] --> Blob[Incoming blob container]
    Blob -->|BlobCreated event| Grid[Event Grid system topic]
    Grid -->|Managed identity sender role| Queue[Service Bus orders queue]
    Consumer[Consumer identity] -->|Receiver role| Queue
    Producer[Separately deployed producer] -.-> Hub[Event Hubs telemetry stream]
    Hub -.-> Analytics[Separately deployed analytics consumer]
```

Event Grid delivers event notifications; it does not copy the blob contents into the queue. The Event Hubs path is a separate streaming example. Producers and consumers must implement retries, idempotency, checkpointing and poison-message handling as appropriate.

## Analytics and AI

Example 09 grants Data Factory, Synapse and the Databricks access connector scoped lake access. Managed private endpoint requests need approval on the storage account. Synapse managed endpoints use a private data-plane API and are configured only after the runner can reach the workspace Dev endpoint.

Example 10 shows private AI service endpoints and workload identities. It does not automatically create Search indexes, connect embeddings to Search, deploy an application, or train a model. Private inbound access also does not complete the Machine Learning managed outbound network.

## State Boundaries

Use a distinct backend key for each environment and example, such as `demo/04-data-services.tfstate`. Keep state infrastructure separate from workloads. A production composition can reuse these module contracts, but shared networking and cross-state dependencies require explicit ownership, lifecycle and access decisions.