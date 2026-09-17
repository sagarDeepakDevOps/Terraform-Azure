# Exercise 8 — Load balancer

The public entry point. Until now nothing outside Azure could reach the web VM.

## What you build

A Standard public load balancer: frontend IP, backend pool, HTTP health probe
and a forwarding rule.

## Run it

```bash
cd exercise8
terraform init
terraform apply
```

## Check it

```bash
curl $(terraform output -raw load_balancer_url)
```

You should get the Apache page. If it hangs, the backend is probably unhealthy:

```bash
az network lb probe list -g <your rg> --lb-name <prefix>-lb -o table
```

## Finish the demo

```bash
terraform output load_balancer_public_ip
```

Put that into `lb_public_ip` in `exercise7/terraform.auto.tfvars` and re-apply
exercise7. The page will then name the load balancer. This **replaces** the web
VM, because the address is baked into cloud-init.

## Worth knowing

**It has no VNet of its own.** A public load balancer is rules in the network
fabric, not a device in a subnet. Its backend pool takes its network from the
NICs added to it, which is why every web VM must share one VNet, and why this
lab's `lb` VNet carries no load-balanced traffic at all.

**It does not rewrite the client address.** Traffic it forwards still arrives at
the VM from the real Internet client, which is why exercise4 needed a rule
allowing port 80 from `Internet` even though no VM is public.

**It is layer 4.** It forwards TCP and does not terminate TLS or read HTTP.
Application Gateway or Front Door do that.

**Azure gives no DNS name by default**, unlike an AWS ALB. An AWS load balancer
*must* give you a name because its node IPs change; an Azure one already has a
static IP you own, so a name is optional. Set `lb_domain_name_label` to get
`<label>.<region>.cloudapp.azure.com`.

**Do not put the jump host in `backend_vm_names`.** It runs no web server, so it
would fail the health probe and drop requests.
