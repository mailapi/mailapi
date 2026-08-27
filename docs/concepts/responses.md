---
title: "Submission responses"
sidebar:
  label: Submission responses
---

| Status | Meaning | Retry guidance |
| --- | --- | --- |
| `200` | Submission completed; returned within an applied `Prefer: wait=N` period or when a keyed terminal result is replayed. This does not confirm final recipient delivery. | Do not retry. |
| `202` | Submission was accepted for asynchronous processing. This is the default success response and does not confirm final recipient delivery. | Do not retry merely because processing is asynchronous. |
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

`202` is the default success status. A client can send `Prefer: wait=N`; if the
provider applies it and submission completes within the wait period, it can
return `200` with `Preference-Applied: wait=N`. The
[design rationale](/concepts/rationale/) explains this bounded-wait contract
and its relationship to submission and delivery.

Error responses use `application/problem+json` with a `type` from the
[problem type registry](/problems/).
