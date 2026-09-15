# 02: Compute and Load Balancing

Creates two private Ubuntu VMs with Nginx installed by cloud-init, a Standard public Load Balancer, an NSG and explicit NAT egress. The default deployment is billable: two VMs, their disks, load balancing, NAT and public IPs.

## Required Input

Supply your SSH public key through `TF_VAR_ssh_public_key`. Do not supply or publish a private key. Review [terraform.tfvars.example](terraform.tfvars.example) for the non-secret options.

| Option | Behavior |
| --- | --- |
| `enable_windows` | Adds a private Windows Server 2022 VM; also requires a complex `windows_admin_password` sensitive input |
| `enable_scale_set` | Adds a Linux VMSS to the load balancer with CPU-based scaling between 1 and 3 instances |
| `enable_backup` | Creates a vault, daily policy and VM protection for the two standalone Linux VMs |

## What to Demonstrate

After cloud-init completes, the `demo_url` output serves HTTP sample content showing the backend hostname. Repeated requests can reach different backends, subject to load-balancer connection hashing. HTTP is intentional for this sample only; do not transmit credentials or business data.

No public SSH/RDP is opened. Administrative access needs an approved Run Command operation or a separately designed private/Bastion path with corresponding NSG rules. Deploying example 03 does not automatically connect it to this lab.

NAT must be ready before cloud-init downloads packages. Check the VM guest logs, Nginx and the health probe if the load balancer is unhealthy. The scale set uses manual image upgrades and demo-sized instances; it is not an HA production baseline.

## Validate and Clean Up

From the project root:

```bash
bash scripts/validate.sh 02-compute
```

The tests exercise the default and all optional components. Fake test keys/passwords are not deployment credentials.

Follow [Docs/DEPLOYMENT.md](../../Docs/DEPLOYMENT.md) before deploying. When backup is enabled, read the retained recovery point and soft-deletion guidance in [Docs/SECURITY-AND-COST.md](../../Docs/SECURITY-AND-COST.md) before teardown.