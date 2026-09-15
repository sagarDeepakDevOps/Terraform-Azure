# Module Design

These are reusable child modules, not directories intended for direct `terraform apply`. Choose an [example](../README.md#choose-an-example) as the root configuration.

## File Contract

| File | Responsibility |
| --- | --- |
| `main.tf` | Azure resources and local child-module composition; most modules also declare compatible providers here |
| `variables.tf` | Required inputs, types, defaults, validation and operational caveats |
| `outputs.tf` | Stable values such as resource IDs, names and hostnames; sensitive values are explicitly marked |
| `versions.tf` | Separate compatibility declaration in the foundational modules |

Provider credentials and provider instances belong to example roots, never to child modules. A common compatibility range is AzureRM `>= 4.81.0, < 5.0.0`; roots constrain the tested minor release and lock exact downloads.

## Ownership and Dependencies

- Resource groups are an independent module. Services receive the group name and region rather than creating hidden resource groups.
- Vnet owns its VNet and calls the nested subnet module. Subnets are standalone resources, never mixed with inline VNet subnet blocks.
- NSGs, routes, peering, DNS, endpoints and paid network appliances are explicitly composed by the root. Directory nesting is organization, not automatic deployment.
- Stable input names drive `for_each`. Values may be resource IDs known after apply, but collection keys must be known during planning.
- Use resource/module outputs to build dependencies. Use `depends_on` when an API prerequisite is not represented by a value, such as a role grant or an already-linked private DNS zone.
- RBAC completion does not guarantee instantaneous authorization propagation. Azure permission caches can still delay first use; do not solve propagation issues by hardcoding credentials.
- Autoscaler-owned instance counts have narrowly scoped `ignore_changes`. Other changes remain visible in plans.

## Adding a Service

1. Add a focused service directory with resources, typed inputs and documented outputs. Keep the chosen SKU and authentication requirements explicit.
2. Declare compatible providers without configuring credentials inside the module.
3. Add a small root example or an explicit opt-in path in a related example.
4. Add a mocked plan run that activates the new path. For important resource-level assertions, use a test run with a direct `module` source rather than trying to traverse hidden child resources.
5. Run `terraform fmt`, initialize the affected example, and run `terraform validate` and `terraform test`.
6. Add the service, region/permission prerequisites, runtime boundary and cost implications to [Docs/SERVICE-CATALOG.md](../Docs/SERVICE-CATALOG.md).

New modules should be understandable on their own. Avoid a universal module with dozens of unrelated service switches, cloud credentials embedded in code, or subscription-wide resources enabled by default.