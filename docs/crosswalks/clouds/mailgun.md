---
title: "Mailgun crosswalk"
sidebar:
  label: Mailgun
---

This crosswalk compares Mail API with Mailgun's Messages API (`POST
/v3/{domain}/messages`). Mailgun is a widely adopted developer-oriented
transactional and marketing email service. An adapter maps an
`OutboundMessageRequest` to Mailgun's form-encoded or multipart endpoint and
normalizes the queued response to Mail API's default `202` or bounded-wait
`200` response.

## References

- [Mailgun Messages API reference](https://documentation.mailgun.com/docs/mailgun/api-reference/openapi-final/tag/Messages/#tag/Messages/operation/createMessage):
  request parameters, form fields, `200` response, and message ID.
- [Mailgun API status codes and errors](https://documentation.mailgun.com/docs/mailgun/api-reference/openapi-final/):
  standard HTTP error responses and error messages.
- [Mailgun Webhooks and tracking](https://documentation.mailgun.com/docs/mailgun/user-manual/tracking-messages/):
  asynchronous delivery, bounce, and engagement event webhooks.

## Potential adapter boundary

Mailgun's Messages API uses `multipart/form-data` or
`application/x-www-form-urlencoded` rather than JSON. The adapter resolves the
target sending domain from the `from` address, constructs the form payload, and
maps Mailgun's response ID to the Mail API submission identifier.

| Mail API field | Mailgun form field | Notes |
| --- | --- | --- |
| `from` | `from` | Formatted mailbox string (`"Example App <noreply@example.org>"`). The sending domain must be registered in the Mailgun account. |
| `to`, `cc`, `bcc` | `to`, `cc`, `bcc` | Comma-separated mailbox strings or repeated parameters. |
| `replyTo` | `h:Reply-To` | Mailgun passes custom and standard RFC 5322 headers through the `h:` parameter prefix. |
| `subject` | `subject` | Direct correspondence. |
| `text`, `html` | `text`, `html` | Mailgun accepts both plain-text and HTML parameters simultaneously, preserving multipart alternative bodies. |
| `headers` | `h:<Header-Name>` | Prefixed header parameters. Forbidden or conflicting structured headers are omitted. |
| `attachments` | `attachment` | Multipart file upload parts. Base64 data from Mail API is decoded to binary before uploading. |
| `Idempotency-Key` request header | Adapter idempotency cache | Mailgun has no native HTTP idempotency key header; the adapter manages execution deduplication locally. |
| submission `id` | Provider-generated Mail API ID mapped to Mailgun's `id` | The Mailgun ID is formatted as `<timestamp.id@domain>` and returned upon queuing. |

Mailgun returns `200 OK` with `{"id": "<...>", "message": "Queued. Thank
you."}` when a message is accepted for processing. An adapter translates this to
Mail API `202 Accepted` by default, or `200` if bounded waiting was applied.

## Response and error mapping

Mailgun status codes describe the provider-level submission result. The adapter
maps these to Mail API status codes and problem types without leaking Mailgun
API keys or domain configurations.

Mail API's `401` and `403` reflect the *caller's* credentials at the Mail API
boundary. If the adapter fails to authenticate with Mailgun, the caller's
request was still structurally valid, so the adapter returns `500`.

| Mailgun result | Mail API response | Adapter handling |
| --- | --- | --- |
| `200 OK` with `id` and `Queued` message | `202` by default; `200` after an applied wait | Store mapping between the Mail API submission `id` and the Mailgun message ID; this confirms queuing, not delivery. |
| `400 Bad Request` | `500` or `422` | Treat serialization defects as `500`; map invalid message structure or rejected parameters to `422`. |
| `401 Unauthorized` | `500` | The adapter's Mailgun API key or endpoint region is invalid; repair adapter configuration. |
| `403 Forbidden` (unauthorized sending domain) | `403` | The caller is not permitted to send using the requested `from` domain under the configured Mailgun account. |
| `403 Forbidden` (account disabled or payment required) | `500` | Operational account failure; repair Mailgun account status. |
| `429 Too Many Requests` | `429` | Propagate rate-limiting backoff to the caller. |
| `5xx`, timeout, or network failure | `500` | The outcome may be indeterminate. Preserve idempotency records to prevent accidental duplicate dispatches. |

## Differences and limits

- Mailgun requires the sending domain to be specified in the endpoint URL path
  (`/v3/{domain}/messages`). The adapter must extract the domain from the
  `from` address and verify that it matches an active sending domain.
- Mailgun uses form-based payload serialization (`multipart/form-data`) rather
  than JSON. Binary attachments are decoded from Mail API's Base64 representation
  into multipart byte streams.
- Provider-specific Mailgun features such as tags (`o:tag`), delivery scheduling
  (`o:deliverytime`), tracking (`o:tracking`), and custom recipient variables
  (`recipient-variables`) can be accommodated via Mail API's `extensions`
  member.
- Mailgun has no native `Idempotency-Key` request header. A robust adapter must
  persist caller idempotency keys to provide safe retries.
