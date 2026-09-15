# 03: Firewall, Bastion and Hybrid Networking

**High-cost lab.** The default creates Standard Azure Firewall and a public IP. Optional Standard Bastion and VpnGw1AZ Gateway add recurring charges and can take substantial time to provision.

## Topology

The hub is `10.40.0.0/16` with reserved AzureFirewallSubnet, AzureBastionSubnet and GatewaySubnet ranges. The spoke is `10.41.0.0/16`; its workload subnet has a real default route through the firewall. Firewall application rules allow only the configured package repository FQDNs. No workload VM is created by this example.

## Optional Inputs

- `enable_bastion = true` creates a Standard Bastion host. The spoke NSG permits SSH/RDP from its dedicated subnet.
- `enable_vpn = true` creates a zone-redundant VPN gateway and enables hub gateway transit on peering. `VpnGw1AZ` uses `Generation1`.
- `on_premises` supplies the real remote VPN public IP and on-premises CIDRs. `vpn_shared_key` is a sensitive input required for that connection.

A remote device, matching IKE/IPsec configuration, compatible address spaces and return routes are required for a working tunnel. The Azure local-network-gateway object does not configure the remote router. Public documentation-range addresses in tests must never be used as real peers.

The firewall DNS proxy is enabled as a capability; workloads retain Azure-provided DNS unless you deliberately configure a DNS architecture. Peering does not create a transit mesh or automatically force all private east-west traffic through the firewall.

## Validate

```bash
bash scripts/validate.sh 03-secure-hub
```

Run from the project root. Tests cover reserved topology, optional hybrid components and the VPN SKU/generation pairing. Read [Docs/DEPLOYMENT.md](../../Docs/DEPLOYMENT.md) and [Docs/SECURITY-AND-COST.md](../../Docs/SECURITY-AND-COST.md) before a real deployment.