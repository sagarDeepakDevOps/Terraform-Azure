# 05: App Service and Flex Consumption Functions

Creates a Linux App Service plan/Web App, a Node 22 Flex Consumption Function App, private deployment/host storage, managed identity grants, NAT, Log Analytics and Application Insights.

## Connectivity and Identity

The Web App uses a subnet delegated to `Microsoft.Web/serverFarms`. Flex Functions uses a different subnet delegated to `Microsoft.App/environments`. Blob, Queue and Table private endpoints have linked DNS zones. NAT provides explicit outbound access for integrated workloads.

Function deployment storage uses a user-assigned identity rather than an account key. Host settings identify the same account and identity. The role grants cover host/deployment storage requirements, scoped to the dedicated account. First use can still be affected by Azure RBAC propagation.

VNet integration is outbound connectivity, not private inbound hosting. These applications expose HTTPS endpoints. Add application authentication, access restrictions or private inbound endpoints for the intended workload.

## What Is and Is Not Deployed

Terraform deploys the hosting resources and configuration. It does **not** deploy a web application or Function package. An initial empty/default page or no registered function routes is expected until code is published. Application Insights also needs appropriate application instrumentation to produce useful telemetry.

Use an approved application deployment workflow with Entra authentication and compatible publishing settings. Basic publishing credentials are disabled. Confirm current Flex Consumption regional and runtime support before planning.

App Service, NAT, storage/endpoints and telemetry have costs even before useful application traffic exists.

## Validate

```bash
bash scripts/validate.sh 05-web-serverless
```

The focused test checks HTTPS enforcement and identity-based storage authentication. Start with [Docs/DEPLOYMENT.md](../../Docs/DEPLOYMENT.md) for a real deployment.