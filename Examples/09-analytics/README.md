# 09: Data Lake, Data Factory, Synapse and Databricks

The default creates an ADLS Gen2 account with `raw`, `curated` and `synapse` filesystems, private storage endpoints, a managed-VNet Data Factory, an identity-based linked service and a small Wait pipeline. It does not load or process customer data.

## Data Factory

The Blob and DFS managed private endpoint requests must be approved on the lake account before the integration runtime can access data. A Blob Data Contributor grant is included; the grant alone does not approve a private connection. The Wait pipeline can illustrate orchestration without running compute or copying data. No scheduled trigger is enabled.

Fully private authoring/browser access can require service portal endpoints and DNS beyond the factory service endpoint shown here. Use a connected client and review current service-specific authoring requirements before adopting the lab in a locked-down enterprise network.

## Optional Synapse

`enable_synapse = true` creates a workspace with SQL, SqlOnDemand and Dev private endpoints. It references the lake's DFS filesystem URL, not a blob container ARM ID. No dedicated SQL pool or Spark pool is created.

Leave `configure_synapse_managed_endpoints = false` for the initial infrastructure deployment. Once the Terraform runner has network and DNS access to the private Synapse Dev endpoint, enable this second-stage flag. The managed endpoint resource uses a service data-plane API; a public runner cannot configure it just because the Azure management API is reachable. Approve the resulting lake connections before workloads use them.

## Optional Databricks

`enable_databricks = true` adds a Premium workspace, dedicated delegated host/container subnets, NSG associations, NAT and an identity-based access connector with lake permissions. Secure cluster connectivity disables public IPs on future cluster nodes. The workspace UI remains an Entra-authenticated public endpoint in this example.

No cluster, notebook, job, Unity Catalog metastore, storage credential or external location is created. Configure these through a separately reviewed Databricks account/workspace deployment. The access connector grant and VNet paths are foundations, not a completed analytics platform.

## Validate

```bash
bash scripts/validate.sh 09-analytics
```

Tests cover the baseline and optional platforms, including the second-stage configuration contract. See [Docs/DEPLOYMENT.md](../../Docs/DEPLOYMENT.md) and [Docs/SECURITY-AND-COST.md](../../Docs/SECURITY-AND-COST.md) before deployment or cleanup.