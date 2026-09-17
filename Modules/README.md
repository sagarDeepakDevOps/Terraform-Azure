# Module Design

These are reusable child modules, not directories you run `terraform apply` in.
The deployable root is [main.tf](../main.tf), which composes all of them into one
lab: two peered virtual networks, Apache VMs, and a public load balancer in front.

## Catalogue

| Module | Creates |
| --- | --- |
| `ResourceGroups` | The single resource group that owns the lab |
| `Networking/vnet` | A virtual network, and its nested `subnets` child module |
| `Networking/vnet/subnets` | Subnets inside that VNet, one per map key |
| `Networking/NSG` | A network security group and its subnet associations |
| `Networking/Peering` | Both directions of a VNet-to-VNet peering |
| `VMS/Linux` | An Ubuntu VM, NIC, optional public IP, its SSH key pair, and the Apache cloud-init |
| `LoadBalancers` | A Standard public load balancer with frontend IP, pool, probe and rule |

`Networking/` is a namespace for every network-layer module, not a module itself:
there is no `Networking/main.tf` and nothing is deployed by pointing a `source` at
the directory. The root calls each submodule underneath it explicitly. `subnets`
sits inside `vnet/` rather than beside it because the VNet module owns its own
subnets; the others are composed by the root because their placement is a
deliberate decision, not an automatic consequence of creating a network.

This branch deliberately carries nothing else. Firewalls, NAT gateways, Bastion,
private DNS and endpoints, route tables, VPN gateways, scale sets, Application
Gateway and Windows VMs were removed to keep the lab readable; recover any of
them from the `main` branch if a later design needs one.

## File Contract

| File | Responsibility |
| --- | --- |
| `main.tf` | Azure resources and local child-module composition; most modules also declare compatible providers here |
| `locals.tf` | Computed values, wherever a module or the root has any |
| `variables.tf` | Required inputs, types, defaults, validation and operational caveats |
| `outputs.tf` | Stable values such as resource IDs, names and addresses |
| `versions.tf` | Separate compatibility declaration in the foundational modules |

Comments are one line each. Anything longer belongs in a `description`, in this
file, or nowhere.

Provider credentials and provider instances belong to the root, never to a child
module. Modules declare the compatible AzureRM range `>= 4.81.0, < 5.0.0`; the
root pins the tested minor release and its lock file records exact downloads.

## Ownership and Dependencies

- Resource groups are an independent module. Services receive the group name and
  region rather than creating hidden resource groups of their own.
- `Networking/vnet` owns its VNet and calls the nested subnet module. Subnets are standalone
  resources, never mixed with inline VNet subnet blocks, so the two resource types
  cannot fight over ownership.
- NSGs and peerings are composed explicitly by the root. Directory nesting is
  organisation, not automatic deployment.
- Stable input names drive `for_each`. Values may be IDs that are unknown until
  apply, but collection *keys* must be known during planning. That is why the
  load balancer is handed a NIC map keyed by VM name rather than a list of IDs.
- Build dependencies out of resource and module outputs. Reach for `depends_on`
  only when an API prerequisite is not represented by any value.
- Passing a value both ways between two modules is safe: Terraform tracks each
  input variable and each output as its own graph node, so the root can show the
  load balancer's address on a VM page while the load balancer pools that VM's NIC.
- `VMS/Linux` generates its own key pair with the `tls` provider rather than taking
  one from `ssh-keygen`, so each VM gets a separate key written to the project root.
  The private keys are therefore stored in Terraform state in plaintext as well as
  on disk, so the state file must be handled as a secret. That is acceptable for a
  throwaway lab and not for anything longer-lived.
