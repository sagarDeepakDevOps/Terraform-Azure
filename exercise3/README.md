# Exercise 3 — Subnets

A subnet is its own Azure resource inside a VNet that already exists.

## What you build

One subnet per inner map key, grouped by the VNet they belong to:

- `frontend` — `10.10.1.0/24` in the lb VNet
- `web` — `10.20.1.0/24` in the workload VNet

## Run it

```bash
cd exercise3
terraform init
terraform apply
```

## Check it

```bash
az network vnet subnet list -g <your rg> --vnet-name <prefix>-workload-vnet -o table
```

## Worth knowing

**Each range must fit inside its VNet's address space.** `10.20.1.0/24` sits
inside `10.20.0.0/16`. A range outside it is rejected.

**Default outbound access is disabled** on these subnets. A VM here has no
Internet path unless it has its own public IP or the subnet has a NAT gateway.
That is why exercise6 exists, and why exercise7's private VM would otherwise
fail to install Apache.

**Do not manage subnets two ways.** Azure lets you declare subnets inline on a
VNet as well. Using both makes two Terraform resources fight over the same
object, so this lab only ever uses the standalone resource.
