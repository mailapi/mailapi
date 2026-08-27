---
title: "Idempotency"
sidebar:
  label: Idempotency
---

To make submission execution safe to retry, clients can supply an
`Idempotency-Key` header containing a unique 1–256 character key of visible
ASCII characters. A provider scopes each key to the authenticated principal
and `POST /v1/messages`, so keys used by different principals cannot collide or
replay one another's responses.

## Processing order

The provider performs preflight checks before reserving a key:

1. Authenticate the caller and authorize the requested sender.
2. Check the media type and request size, parse the JSON, and validate the
   message.
3. Apply rate-limit admission.

Responses from those checks (`400`, `401`, `403`, `413`, `415`, `422`, and
`429`) are not stored. A client can correct the request and retry with the same
key.

After preflight succeeds, the provider atomically associates the key with the
byte-for-byte UTF-8 request body and begins submission execution. JSON
whitespace and object-member ordering are significant.

- Reusing the key with a different body returns
  [`idempotency-key-reused`](/problems/).
- Retrying while the matching execution is still in progress returns
  [`idempotency-key-in-progress`](/problems/).
- A `503` means execution did not begin. The key is not retained, so the caller
  may retry the same request and key after the indicated delay.

Both conflict conditions use status `409` and are not replayed outcomes.

## Stored outcomes

The initial `202` response is not a terminal outcome and is not stored as the
result. A matching retry while execution continues returns the `409`
in-progress problem described above.

Once execution produces a terminal `200` or `500`, the provider stores its
status and body for 24 hours. A matching retry returns that response without
executing another submission and adds `Idempotency-Replayed: true`. A newly
processed response omits the header.

Replaying a stored `500` preserves duplicate safety but does not resolve its
unknown delivery outcome. Using a new key would start another submission and
therefore requires a caller policy that accepts duplicate risk.

After 24 hours the association is forgotten. A later request using the same key
starts a new submission.
