# Hub and Spoke

A hub-and-spoke network on Azure, built with Terraform. It is self-contained:
its own modules, its own remote-state storage ([backend-prereq](backend-prereq/)),
and no resources shared with the labs on the `main` branch.

In the earlier labs, two VNets are peered directly, and the private subnet
reaches the Internet through its own NAT gateway. Here each spoke peers only
with a central hub, and all traffic leaving a spoke goes through the hub's
Azure Firewall: traffic to the Internet, traffic to another spoke, and replies
to Internet clients. No VM has a public IP.

```
                                  Internet
                 HTTP :80 to the      |      egress to *.ubuntu.com only,
                 firewall public IP   |      from the firewall public IP
                                      |
+-- hub-vnet 10.0.0.0/22 -------------+---------------------------------------+
|   AzureFirewallSubnet            10.0.0.0/26    Azure Firewall Basic 10.0.0.4 |
|   AzureFirewallManagementSubnet  10.0.0.64/26   (the Basic tier needs it)     |
|   AzureBastionSubnet             10.0.1.0/26    Azure Bastion Standard        |
+--------------+-----------------------------------------------+---------------+
       peering |                                               | peering
+-- web-vnet 10.1.0.0/16 --------+          +-- api-vnet 10.2.0.0/16 ----------+
|   frontend 10.1.1.0/24         |          |   backend 10.2.1.0/24            |
|     NSG                        |          |     NSG                          |
|     route 0.0.0.0/0 -> fw      |          |     route 0.0.0.0/0 -> fw        |
|     web1 10.1.1.10  (Apache)   |          |     api1 10.2.1.10  (Apache)     |
+--------------------------------+          +----------------------------------+

Everything is in one resource group, <prefix>-rg.
```

The two spokes are not peered with each other. Peering is not transitive, so
the only way from `web` to `api` is through the firewall, and the firewall
decides whether the traffic is allowed. That is what makes it hub and spoke
rather than a mesh.

## The four traffic paths

Everything the lab does is one of these. Each path is controlled in more than
one place, and a missing piece in any of them drops the traffic.

### 1. Internet to web1

```
browser -> firewall public IP :80 -> DNAT -> web1 10.1.1.10 :80
```

- **Firewall:** `firewall_dnat_rules` in tfvars. `web1-http` publishes web1's
  port 80 on the firewall's public IP. The VM needs a static
  `private_ip_address`, because a DNAT rule targets an address.
- **NSG on `frontend`:** allows port 80 from `10.0.0.0/26`, the
  AzureFirewallSubnet range, **not** from `Internet`. The firewall SNATs
  DNAT'd traffic to one of its own instance addresses. On a live run web1's
  Apache log showed requests from `10.0.0.5` and `10.0.0.6`, never from the
  client.

### 2. Spoke to spoke

```
web1 -> route 0.0.0.0/0 -> firewall -> network rule web-to-api-http -> api1
```

- **Route table:** a spoke's VNet knows only its own range and, through the
  peering, the hub's. `10.2.0.0/16` matches neither, so it falls to
  `0.0.0.0/0`, whose next hop is the firewall. The reply takes the same route
  back, so the firewall sees both directions of the connection.
- **Firewall:** `firewall_network_rules` in tfvars. Rules name spokes rather
  than CIDRs, and [locals.tf](locals.tf) looks the ranges up. Rules are
  stateful and one-way: `web` may open connections to `api` on port 80, but
  `api` cannot open one to `web`.
- **NSG on `backend`:** allows port 80 from `10.1.0.0/16`. Traffic between
  private ranges is not SNATed, so the source address really is web1's.
- **Peering:** `allow_forwarded_traffic` must be true on the spoke side,
  because packets from another spoke arrive with a source address that is not
  the hub's own.

A ping from api1 to web1 comes back with `ttl=63` instead of 64: the one hop is
the firewall.

### 3. Spoke to the Internet

```
api1 -> route 0.0.0.0/0 -> firewall -> application rule ubuntu-packages -> *.ubuntu.com
```

- **Subnets are private.** `default_outbound_access_enabled = false` in the
  spoke module, so without the route there is no Internet access at all. There
  is no NAT gateway anywhere.
- **Firewall:** `firewall_application_rules` in tfvars allows by FQDN, and
  everything else is denied. `curl http://www.microsoft.com` from a VM gets the
  firewall's own reply: `Action: Deny. Reason: No rule matched.`
- **Order matters on first boot.** cloud-init installs Apache from
  `*.ubuntu.com`, so the firewall and its rules must exist before any VM boots.
  The code enforces this. The firewall `depends_on` its rules, the spoke route
  needs the firewall's IP, and the spoke's `subnet_ids` output `depends_on` the
  NSG, the route table and the peering. A VM cannot get its subnet ID any
  earlier.

### 4. You to a VM

```
az network bastion ssh -> Bastion (hub) -> peering -> VM :22
```

- **NSGs:** both spokes allow port 22 only from `10.0.1.0/26`, the
  AzureBastionSubnet range. There is no jump host and nothing to SSH to
  directly.
- **Bastion SKU:** `Standard` supports `az network bastion ssh` from your
  terminal. `Basic` is cheaper but works only from the portal's Connect button.

## Modules

Root [main.tf](main.tf) holds module calls only. The `hub` and `spoke` modules
are built from networking **sub-modules**. Two of those contain a **child
module** for a part that repeats.

```
./                                  branch root
├── main.tf                         module calls only
├── locals.tf                       spoke keys -> CIDRs, DNAT rules from the VM map
├── backend.tf                      remote state, key hub-spoke.tfstate
├── variables.tf  outputs.tf  terraform.auto.tfvars
├── backend-prereq/                 separate root with local state: creates the state storage
└── modules/
    ├── resource-group/             one resource group; used by the root and by backend-prereq
    ├── storage/
    │   └── tfstate/                storage account + container for remote state
    ├── hub/                        hub VNet + firewall + Bastion
    ├── spoke/                      spoke VNet + NSG per subnet + route to firewall + peering
    ├── networking/                 sub-modules used by hub and spoke
    │   ├── vnet/
    │   │   └── subnet/             child module, one per subnet
    │   ├── nsg/                    NSG, rules, subnet association
    │   ├── route-table/            route table, routes, subnet association
    │   ├── peering/                both halves of a hub-spoke peering
    │   ├── firewall/               public IPs, policy, firewall
    │   │   └── rule-collection-group/   child module: DNAT, network and application rules
    │   └── bastion/                public IP, Bastion host
    ├── compute/
    │   └── linux-vm/               NIC, VM, cloud-init template for Apache
    └── security/
        └── ssh-key/                one key pair for every VM (key.tf)
```

| Called from | Module | Called with |
| --- | --- | --- |
| root | `hub` | once |
| root | `spoke` | `for_each = var.spokes` |
| root | `compute/linux-vm` | `for_each = var.vms` |
| `hub`, `spoke` | `networking/vnet` | once each |
| `vnet` | `vnet/subnet` | `for_each` over the subnets |
| `spoke` | `networking/nsg` | `for_each` over the subnets |
| `firewall` | `firewall/rule-collection-group` | once, holding every rule |
| `backend-prereq` | `resource-group`, `storage/tfstate` | once each |

## Before you start

You need Terraform >= 1.9 and the Azure CLI, and a subscription you may create
resources in. Sign in, and export the subscription in the shell you run
Terraform from:

```bash
az login
az account set --subscription "<your subscription>"
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
```

This lab uses **3 public IPs** (firewall data, firewall management, Bastion)
and **4 vCPUs** (two `Standard_D2ls_v7`). Check the region has room:

```bash
az network list-usages --location eastus2 \
  --query "[?name.value=='PublicIPAddresses']" -o table
az vm list-usage --location eastus2 \
  --query "[?name.value=='cores' || name.value=='StandardDlsv7Family']" -o table
```

## Deploy

Two roots, applied in order. The state storage has to exist before anything
can keep its state in it.

**1. State storage, once.** [backend-prereq](backend-prereq/) keeps its own
state locally, because a backend cannot store itself. It creates
`<prefix>-tfstate-rg`, a storage account and a `tfstate` container, and writes
`backend.hcl` into this directory:

```bash
cd backend-prereq
terraform init
terraform apply
```

**2. The network.** `backend.tf` declares only the state key. The rest comes
from `backend.hcl` on the command line:

```bash
cd ..
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

If this directory already has a local `terraform.tfstate`, add
`-migrate-state` to that `init`. Terraform uploads the local state and asks you
to confirm. Check the blob is in the container, then delete the local
`terraform.tfstate` and its backup.

It creates 44 resources in about 12 minutes. Most of that is the firewall
(about 8 minutes) and Bastion (about 10), which are built in parallel.

`terraform apply` returns before cloud-init has finished installing Apache.
Allow another two minutes before the page answers.

## Test it

Each step checks one of the four paths. Run them from this directory.
`az vm run-command` runs a command inside a VM without SSH, which is handy
here because nothing has a public IP.

```bash
RG=$(terraform output -raw resource_group_name)
FW=$(terraform output -raw firewall_public_ip)
run() { az vm run-command invoke -g "$RG" -n "azure-terra-hs-$1" --command-id RunShellScript \
          --scripts "$2" --query "value[0].message" -o tsv; }
```

**0. cloud-init finished on both VMs.** Expect `status: done` and `active`:

```bash
run web1 "cloud-init status; systemctl is-active apache2"
run api1 "cloud-init status; systemctl is-active apache2"
```

**1. Internet to web1, through DNAT.** Expect `Hello from web1`:

```bash
curl -s "http://$FW" | grep -o 'Hello from web1'
run web1 "grep -v '^168.63.129.16' /var/log/apache2/access.log | awk '{print \$1}' | sort | uniq -c"
```

The second command shows who web1 thinks the client was: `10.0.0.5` and
`10.0.0.6`, the firewall instances.

**2. Spoke to spoke, allowed one way only:**

```bash
run web1 "curl -s -m 5 http://10.2.1.10 | grep -o 'Hello from api1'"   # allowed by web-to-api-http
run api1 "curl -s -m 5 http://10.1.1.10"                               # Action: Deny. Reason: No rule matched.
run api1 "ping -c 2 10.1.1.10"                                         # replies, ttl=63
```

**3. Egress, filtered by FQDN:**

```bash
run api1 "curl -s -o /dev/null -w '%{http_code}\n' http://azure.archive.ubuntu.com/ubuntu/"   # 200
run api1 "curl -s -m 5 http://www.microsoft.com"                                              # Action: Deny
run api1 "curl -s -m 5 -o /dev/null -w '%{http_code}\n' https://www.bing.com"                 # 000, TLS refused
```

**4. SSH through Bastion.** Each VM has a ready-made command. The first run
asks to install the `bastion` and `ssh` Azure CLI extensions:

```bash
eval "$(terraform output -json bastion_ssh_commands | jq -r .web1)"
```

## Growing it

Everything is a map in [terraform.auto.tfvars](terraform.auto.tfvars). None of
these needs an HCL change.

**Add a spoke.** Add an entry to `spokes` with a range that overlaps nothing.
It gets its own VNet, NSGs, route to the firewall and peering with the hub. It
cannot reach anything until you give it firewall rules. Add it to
`firewall_application_rules.ubuntu-packages.source_spokes` so its VMs can
install packages, and add a `firewall_network_rules` entry for any spoke it
should talk to.

**Add a VM.** Add a key to `vms` naming its `spoke_key` and `subnet_key`. Set
`install_apache = false` for a plain host.

**Publish another VM.** Give it a `private_ip_address`, then add an entry to
`firewall_dnat_rules`. Set `public_port` if port 80 is already taken on the
firewall. Also allow the port from `10.0.0.0/26` in that subnet's NSG.

**Allow a new flow between spokes.** It needs two changes, one at each layer:
a `firewall_network_rules` entry in the hub, and an NSG rule on the
destination subnet allowing the source spoke's CIDR. Missing either one drops
the traffic.

## Cost

Approximate eastus2 pay-as-you-go prices while it is running:

| Resource | Per hour |
| --- | --- |
| Azure Firewall Basic | ~$0.40 plus $0.065 per GB processed |
| Azure Bastion Standard | ~$0.29 (Basic is ~$0.19) |
| 2 x Standard_D2ls_v7 | ~$0.17 |
| 3 Standard public IPs | ~$0.015 |

Roughly **$0.90 an hour**, or about $21 a day if you forget it. Destroy it when
you finish.

## Tear it down

```bash
terraform destroy
```

It takes about 15 minutes; the firewall and Bastion are slow to delete. Then
confirm nothing is left:

```bash
az group exists -n azure-terra-hs-rg   # should print false
```

Leave the state storage in place between sessions; it costs cents a month.
Destroy it only when you are finished for good, and only after the network is
gone. Otherwise the network's state goes with it:

```bash
terraform -chdir=backend-prereq destroy
```

## Troubleshooting

**The page times out.** Check, in order:
1. cloud-init finished (step 0 above). If apt failed, the egress rule did not
   cover a host it needed.
2. The `frontend` NSG allows port 80 from AzureFirewallSubnet (`10.0.0.0/26`).
   A rule allowing `Internet` matches nothing here, because the firewall SNATs
   the client away.
3. The DNAT rule's `vm_key` names a VM whose `private_ip_address` is what the
   VM really has: `terraform output vm_private_ips`.

**Spoke-to-spoke traffic fails although the firewall rule exists.** The
destination subnet's NSG also has to allow it, with the source spoke's CIDR.

**`az network bastion ssh` says the feature is not supported.** `bastion_sku`
is `Basic`. Use the portal, or change it to `Standard` and apply.

**`SkuNotAvailable` for a VM.** Pick a size your subscription allows in the
region:

```bash
az vm list-skus --location eastus2 --resource-type virtualMachines --all \
  --query "[?!restrictions && starts_with(name,'Standard_D2')].name" -o tsv
```

**`PublicIPCountLimitReached`.** This lab needs 3 public IPs, on top of any
other lab you have running in the same region.

## A note on security

web1 serves plain HTTP on the firewall's public IP, open to the whole
Internet. Do not put anything real on it. The generated private key is in
`azure-terra-hs-ssh-key.pem` and in `terraform.tfstate`, in plaintext.
`.gitignore` already excludes both.
