---
title: "Submission responses"
sidebar:
  label: Submission responses
---

| Status | Meaning | Retry guidance |
| --- | --- | --- |
| `200` | Provider accepted responsibility for asynchronous processing; this does not confirm final recipient delivery. | Do not retry. |
| `400` | Malformed JSON or invalid request syntax. | Correct the request first. |
| `401` | Credentials are missing, malformed, or invalid. | Fix credentials first. |
| `403` | Credentials are valid but not authorized for this submission. | Fix authorization first. |
| `409` | `Idempotency-Key` conflicts with a different payload or matching request still in progress. | Use a new key for a different message; retry a matching in-progress request later. |
| `413` | Request body or attachment content exceeds a provider limit. | Reduce the request first. |
| `415` | Unsupported request media type. | Correct the request first. |
| `422` | Message fields are semantically invalid. | Correct the message first. |
| `429` | Submission rate limit exceeded. | Retry after `Retry-After` when provided. |
| `500` | Unexpected provider error; the submission outcome may be unknown. | A matching `Idempotency-Key` safely replays the stored `500` but does not execute again. A new key or an unkeyed retry risks a duplicate. |
| `503` | Provider is temporarily unable to accept the message; execution did not begin. | Retry the same request and key after `Retry-After` when provided. |

`200` is the only success status, and it means acceptance rather than delivery.
The [design rationale](/concepts/rationale/) records why the contract uses `200`
rather than `202`, and how that lines up with SMTP, JMAP, and each cloud
provider.

Error responses use `application/problem+json` with a `type` from the
[problem type registry](/problems/).
