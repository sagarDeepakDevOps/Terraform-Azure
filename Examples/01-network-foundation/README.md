# 01: Network Foundation

The recommended first walkthrough. This lab creates a resource group, hub/spoke VNets, named subnets, both peering directions, a web NSG, a route table and a private DNS zone linked to both VNets.

## Inputs and Behavior

Use [terraform.tfvars.example](terraform.tfvars.example) for prefix, region and tags. No secret or extra required input is needed. The hub uses `10.10.0.0/16`; the spoke uses `10.20.0.0/16`.

The web subnet allows HTTPS from the hub and denies other inbound traffic. The app subnet is topology-only and still has Azure's default network behavior. The UDR discards the documentation-only `192.0.2.0/24` range; it does not send traffic to an appliance that does not exist. Default outbound access is disabled on all subnets.

No VM, gateway, firewall, public IP or NAT is created. Private DNS and peering traffic can still incur charges. There is no application endpoint to open in a browser.

## Walkthrough

Open [main.tf](main.tf), follow its VNet `source` into [Modules/Vnet/main.tf](../../Modules/Vnet/main.tf), then inspect the nested subnet module. Notice how the resource group and VNet outputs establish dependencies.

From the project root, without Azure credentials:

```bash
bash scripts/validate.sh 01-network-foundation
```

Tests cover naming, address space, named subnet outputs and disabled implicit egress. Follow [Docs/DEPLOYMENT.md](../../Docs/DEPLOYMENT.md) for a real plan/apply, and [Docs/SECURITY-AND-COST.md](../../Docs/SECURITY-AND-COST.md) for cleanup.