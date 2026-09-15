# 04: Private Storage and Database Services

Creates a private StorageV2 account with Blob containers, an SMB file share, a queue and a Table; a purge-protected Key Vault; a user-assigned identity and scoped grants; and Azure SQL by default. PostgreSQL, MySQL, Cosmos DB and Azure Managed Redis are independently selectable.

## Select Engines

Edit the `databases` object shown in [terraform.tfvars.example](terraform.tfvars.example). Every enabled engine incurs its own charges. Changing an enabled engine to false after deployment plans deletion of that engine; it is not a pause button.

| Engine | Connectivity and authentication |
| --- | --- |
| SQL | `sqlServer` private endpoint; TLS; demo user `sqladmin` |
| PostgreSQL | Dedicated delegated subnet and private DNS; TLS; demo user `pgadmin` |
| MySQL | Separate delegated subnet and private DNS; required secure transport; demo user `mysqladmin` |
| Cosmos DB | `Sql` private endpoint, serverless NoSQL, application identity data role; local keys disabled |
| Managed Redis | `redisEnterprise` private endpoint, encrypted protocol and provider-reported database port; demo access key |

SQL/PostgreSQL/MySQL share the generated `database_admin_password` in this teaching example. It is a sensitive output and is stored in state. Retrieve it only through an approved private operational channel, not in a screenshot or presentation. Production should use separate credentials/identities and non-administrator application users.

## Important Boundaries

The lab creates the private service network but not a VPN, jump host or user workstation. Connect from an authorized client that can route to `10.50.0.0/16` and resolve its linked private DNS zones. Use normal service FQDNs for TLS connections, not hardcoded private IPs.

The application identity has Blob and Key Vault data roles, but no application is attached to it automatically. Cosmos receives its distinct NoSQL data role when enabled. File-share creation is infrastructure only: configure a supported SMB identity/domain integration and share/NTFS permissions before mounting. Shared storage keys remain disabled.

The lifecycle policy tiers and ultimately deletes matching `data/` blobs. Review it before storing real data. Key Vault contains no seeded secrets, and purge protection prevents immediate name reuse after deletion. Managed Redis uses a small non-HA SKU; confirm regional availability.

## Validate

```bash
bash scripts/validate.sh 04-data-services
```

Tests activate all five database engines and assert private, key-disabled Storage defaults. See [Docs/DEPLOYMENT.md](../../Docs/DEPLOYMENT.md) and [Docs/SECURITY-AND-COST.md](../../Docs/SECURITY-AND-COST.md) for deployment and retention-aware cleanup.