# 08: Messaging, Events, Workflows and APIs

Creates Service Bus with a queue/topic/subscription, Event Hubs with a stream/consumer group, private source storage, an Event Grid system topic and queue-delivery subscription, and a disabled-by-default Logic App.

## Demonstration Paths

- Upload a blob into `incoming` from an authorized private-network client. Event Grid filters BlobCreated events and delivers the notification to the `orders` Service Bus queue using its system-assigned identity.
- Event Hubs is a separate partitioned telemetry stream. Deploy a producer and consumer separately; the lab provisions infrastructure and a consumer identity, not event-generating software.
- Set `enable_workflow = true` to enable the daily recurrence/Compose Logic App. It does not call third-party services or require connector credentials.
- Set `enable_api_management = true` with a real `publisher_email` to deploy paid Developer APIM. Its `/demo/health` operation uses a response policy, HTTPS, rate limiting and a subscription requirement.

Create and approve a subscription for APIM's Demo product before sending its subscription key from a secure client. No subscription key is hardcoded or printed by this project. Developer APIM has no production SLA and is not a fast resource to provision during a presentation.

## Security and Cost

Service Bus and Event Hubs use Entra authentication with public service endpoints. Shared local keys are disabled. Service Bus private networking is a separate Premium design. The consumer identity has receive roles, not permission to provision infrastructure or publish arbitrary events.

Event Grid forwards metadata, not the full blob. Applications remain responsible for idempotency, dead-letter processing and retry behavior. The namespace capacity, Private Link, storage and enabled workflow/API options are billable.

## Validate

```bash
bash scripts/validate.sh 08-integration
```

Tests exercise default messaging and the API/workflow options. Read [Docs/DEPLOYMENT.md](../../Docs/DEPLOYMENT.md) for real Azure prerequisites.