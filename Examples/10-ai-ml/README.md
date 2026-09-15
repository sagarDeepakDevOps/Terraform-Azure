# 10: AI Services, OpenAI, Search and Machine Learning

The default creates a private multi-service AI account, private Basic AI Search, an application identity, scoped AI/Search roles and matching private DNS. Search capacity and Private Link are billable even before an application uses them.

## Optional OpenAI

Set `enable_openai = true` to create the private account. `openai_deployments` is empty by default, so no inference model is deployed unless you explicitly supply its model name, version, deployment SKU and capacity.

Confirm current model availability, retirement schedule, subscription eligibility, quota and regional/data-residency behavior before applying. `GlobalStandard` is a deployment choice with its own processing/residency implications. The historical model in the mocked test is only a configuration fixture; it does not assert that this model/version is currently deployable in your region.

The application identity receives Cognitive Services OpenAI User when enabled. An endpoint alone is insufficient: clients need network access, Entra authorization and a valid deployment name.

## Optional Machine Learning

`enable_machine_learning = true` creates a private ML workspace with dedicated non-HNS storage, Key Vault, monitoring and a pre-authorized user-assigned identity. Storage access uses `Identity`, not an account key. Private workspace DNS includes API and notebook zones.

The managed network is configured but not provisioned at workspace creation. Before training or inference, provision/approve the necessary managed outbound private connections, choose compute, configure image building/registry access and grant appropriate user permissions. No training cluster, notebook VM, model, managed endpoint or serverless compute job is launched by this example.

## Application Boundary

Search index creation/ingestion, vector schemas, embedding calls, RAG orchestration, data preparation, model evaluation and application deployment are intentionally separate. The sample app identity's Search Index Data Contributor role supports document data access; index administration requires an appropriate service role granted deliberately.

No local AI/Search API keys are enabled. Private clients and correctly linked DNS are required; the lab does not create a laptop VPN.

## Validate

```bash
bash scripts/validate.sh 10-ai-ml
```

Tests cover default identity settings and explicitly selected ML/model paths. Follow [Docs/DEPLOYMENT.md](../../Docs/DEPLOYMENT.md) before using a real subscription.