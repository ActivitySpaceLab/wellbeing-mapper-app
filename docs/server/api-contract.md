# API Contract (Draft)

List every endpoint the mobile app calls, the payload schema, and expected responses.

| Endpoint | Method | Description | Auth | Notes |
| --- | --- | --- | --- | --- |
| `/surveys/encrypted` | POST | Upload encrypted survey payloads | RSA-hybrid | Document request body + response codes |
| `/consent/encrypted` | POST | Upload encrypted consent responses | RSA-hybrid | Include PII handling notes |
| `/locations/encrypted` | POST | Upload location batches | RSA-hybrid | Mention throttling and retries |
| `/participants/register` | POST | Participant self-registration | TBD | Define validation rules |
| `/participants/validate` | POST | Validate participant code | TBD | Confirm rate limits |

Add JSON examples, error shape, and retry/backoff guidance as you lock in the server implementation.
