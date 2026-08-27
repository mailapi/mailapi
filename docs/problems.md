---
title: "Problem types"
sidebar:
  label: Problem types
---

Every unsuccessful Mail API response uses `application/problem+json`
([RFC 9457](https://www.rfc-editor.org/rfc/rfc9457.html)). The `type` member
carries a stable, specification-owned identifier so that a client can match a
condition across providers.

## Why the specification owns these URIs

A vendor-neutral API is only portable if its error identifiers are portable. If
each provider published problem types under its own origin, a client could not
branch on `type` without knowing which provider it was talking to, and
`Idempotency-Key` conflict handling in particular would stop being reusable.

Conformant providers therefore use the `type` values below unchanged, on their
own origin, without rewriting the URI to their own host.

These URIs are stable identifiers rather than live pages. RFC 9457 recommends
that a `type` URI provide documentation when dereferenced, but does not require
it; this page is that documentation.

## Registry

| Problem type | Status | Meaning |
| --- | --- | --- |
| `https://mailapi.github.io/problems/malformed-request` | `400` | Malformed JSON or invalid request syntax. |
| `https://mailapi.github.io/problems/unauthenticated` | `401` | Credentials are missing, malformed, or invalid. |
| `https://mailapi.github.io/problems/forbidden` | `403` | Credentials are valid but not authorized for this submission. |
| `https://mailapi.github.io/problems/idempotency-key-reused` | `409` | The key was already used with a different request body. |
| `https://mailapi.github.io/problems/idempotency-key-in-progress` | `409` | A matching submission using this key is still in progress. |
| `https://mailapi.github.io/problems/payload-too-large` | `413` | Request body or attachment content exceeds a provider limit. |
| `https://mailapi.github.io/problems/unsupported-media-type` | `415` | Unsupported request media type. |
| `https://mailapi.github.io/problems/invalid-message` | `422` | Message fields are syntactically valid but semantically invalid. |
| `https://mailapi.github.io/problems/rate-limit-exceeded` | `429` | Submission rate limit exceeded. |
| `https://mailapi.github.io/problems/provider-error` | `500` | Unexpected provider error; the submission outcome may be unknown. |
| `https://mailapi.github.io/problems/provider-unavailable` | `503` | The provider did not accept the message and is temporarily unavailable. |

See the [submission response table](/concepts/responses/) for retry guidance
per status code.

## Extending the registry

A provider may define additional `type` values under its own namespace for
conditions this specification does not name. It must not reuse a
`https://mailapi.github.io/problems/` URI for a different meaning, and it must
not substitute a proprietary URI for a condition that is already registered
here.

Because `Problem` allows additional members, a provider can also attach
machine-readable detail (for example a field-level error list) alongside the
registered `type`. Clients should ignore members they do not recognize.

## Matching on `type`, not `status`

Two registered types share status `409`, and `500` covers any unexpected
provider failure. Clients that need to distinguish those conditions must
compare the `type` member rather than the status code alone.
