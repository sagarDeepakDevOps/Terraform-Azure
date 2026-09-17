# Exercise 4 — Network security groups

A firewall for each subnet. Until now nothing was filtered.

## What you build

One NSG per subnet, each carrying only that subnet's rules:

- `lb-frontend` — SSH from your IP only, then deny everything
- `workload-web` — HTTP from Internet and from the load balancer probe, ICMP/SSH/HTTP from peered VNets, then deny everything

## Before you run it

Replace the IP in `allow_ssh_admin` with your own public address, or you will not
be able to SSH in during exercise7.

```bash
curl https://api.ipify.org
```

Be careful: some ISPs show Azure a **different** address than they show that
site. If SSH later times out, see the root README's troubleshooting section for
how to read the address Azure actually saw.

## Run it

```bash
cd exercise4
terraform init
terraform apply
```

## Check it

```bash
az network nsg rule list -g <your rg> --nsg-name <prefix>-workload-web-nsg -o table
```

## Worth knowing

**Lower priority numbers win.** `deny_other_inbound` sits at 4096 so everything
else is evaluated first. Put a rule above it or it never matters.

**Service tags beat CIDRs.** `VirtualNetwork` covers this VNet *and* its peers,
so the jump host is allowed without hardcoding `10.10.1.0/24`.
`AzureLoadBalancer` is the health probe, and without it every probe fails and
the load balancer serves nothing.

**`Internet` does not match a private source.** The `allow_http_from_lb_clients`
rule allows port 80 from `Internet`, but a jump host at `10.10.1.4` is not
`Internet`, so `allow_http_from_vnets` is what makes `curl http://10.20.1.4`
work from the jump host.
