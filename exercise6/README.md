# Exercise 6 — NAT gateway

Outbound Internet for a subnet whose VMs have no public IP.

## What you build

A NAT gateway and its public IP, attached to the `web` subnet.

## Run it

```bash
cd exercise6
terraform init
terraform apply
```

## Check it

```bash
terraform output nat_gateway_public_ips
az network nat gateway show -g <your rg> -n <prefix>-workload-web-nat -o table
```

## Why this exists

Exercise3's subnets have default outbound access disabled, and exercise7's web
VM has no public IP. Without a NAT gateway that VM cannot reach the Ubuntu apt
mirrors, so cloud-init never installs Apache and the site silently never works.
The VM builds fine — it just serves nothing.

Apply this **before** exercise7.

## Worth knowing

**It is outbound only.** A NAT gateway accepts no inbound connections. It is not
a way to reach your VMs; that is the load balancer's job.

**It costs money** — roughly $32/month plus data, on top of the public IP. It is
usually the most expensive thing in this lab.

**It consumes one of your public IPs.** Free subscriptions allow only 3 per
region, and this lab uses all 3 (load balancer, jump host, NAT gateway).

**It overrides load balancer outbound SNAT.** When a subnet has a NAT gateway,
Azure routes outbound traffic through it regardless of any load balancer rule.
