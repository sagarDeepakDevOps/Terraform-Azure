# Exercise 5 — VNet peering

Connect the two networks privately, so the jump host can reach the web subnet
without going over the Internet.

## What you build

Both directions of a peering between the lb and workload VNets. A peering is two
resources, one on each side; a single direction connects nothing.

## Run it

```bash
cd exercise5
terraform init
terraform apply
```

## Check it

```bash
az network vnet peering list -g <your rg> --vnet-name <prefix>-lb-vnet -o table
```

Both should show `peeringState: Connected`. If one says `Initiated`, the other
half is missing.

## Worth knowing

**Peering is not transitive.** If A peers B and B peers C, A still cannot reach
C. You would need a third peering, or a hub appliance with routing.

**It does not bypass NSGs.** The rules from exercise4 still apply in both
directions. Peering makes traffic *possible*, not *permitted*.

**You cannot peer overlapping address spaces**, which is why exercise2 used
`10.10.0.0/16` and `10.20.0.0/16`.

**Nothing uses this yet.** The load balancer in exercise8 does *not* cross this
peering. You will use it in exercise7 when you ping the private VM from the jump
host.
