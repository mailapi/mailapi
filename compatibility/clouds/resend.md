# Resend compatibility

This assessment compares Mail API with Resend's Email API. An adapter converts
an `OutboundMessageRequest` to Resend `POST /emails`, then normalizes a
successful Resend response to Mail API's `200` response. It does not require a
Mail API provider to use Resend.

## References

- [Resend send-email reference](https://resend.com/docs/api-reference/emails/send-email) — request fields, `200` response, email ID, and `Idempotency-Key`.
- [Resend API introduction](https://resend.com/docs/api-reference/introduction) — standard API error status codes.
- [Resend usage limits](https://resend.com/docs/api-reference/rate-limit) — `429` and rate-limit response headers, including `retry-after`.

## Potential adapter boundary

Resend's send-email request directly represents most Mail API message fields.
The adapter maps the accepted Resend email `id` to the Mail API accepted-message
identifier and returns `200`; that acceptance is not final recipient delivery.

| Mail API field | Resend mapping | Notes |
| --- | --- | --- |
| `from` | `from` | Format the display name and email address as a mailbox string. |
| `to`, `cc`, `bcc` | `to`, `cc`, `bcc` | Convert address objects to mailbox strings. |
| `replyTo` | `reply_to` | Convert the address list to the provider representation. |
| `subject`, `text`, `html` | `subject`, `text`, `html` | Preserve both body alternatives when provided. |
| `headers` | `headers` | Resend custom headers are an object, so repeated header names cannot be preserved without an explicit adapter policy. |
| `attachments` | `attachments` | Map filename and Base64 content; enforce Resend attachment limits. |
| `Idempotency-Key` request header | `Idempotency-Key` request header | Forward the client-supplied key unchanged. |
| accepted response `id` | Resend email `id` | This identifies a Resend email, not a Mail API delivery-status endpoint. |

## Response and error mapping

Resend status codes are provider-facing responses. The adapter converts them to
Mail API's public contract and must not expose Resend API keys or account
configuration to the caller.

| Resend result | Mail API response | Adapter handling |
| --- | --- | --- |
| `200` with an email `id` | `200` | Return the Resend ID as the accepted-message `id`. |
| `400` malformed request | `500` | Treat invalid generated Resend request syntax or serialization as an adapter defect. |
| `400` provider validation failure | `422` | The Mail API message is unacceptable under the selected Resend provider policy. |
| `409` idempotency-key conflict | `409` | Preserve the distinction between a different payload and an in-progress matching request. |
| `401`, `403`, or provider domain/account configuration failure | `500` | Repair adapter credentials, authorization, or Resend account configuration. |
| `429` | `429` | Apply backoff and propagate a `Retry-After` value when available. |
| Resend `5xx`, timeout, or connection failure | `500` | The submission outcome can be unknown; retry only under a duplicate-risk policy. |

Use `503` only when the adapter knows it did not submit the message and is
temporarily unable to accept it. Once a request may have reached Resend, return
the unknown-outcome `500` contract instead.

## Idempotency and provider features

Resend supports an `Idempotency-Key` request header that prevents duplicate
emails for 24 hours. Mail API `v1` uses the same optional header and retention
period, so an adapter forwards a supplied key unchanged. It must not derive a
key from message content: identical content can be a legitimate second
submission. Reusing a key with a different payload returns `409`.

Resend can retrieve sent-email records and their latest provider event. Those
records, delivery events, templates, tags, scheduling, and API-key management
are provider features; they do not define Mail API `v1` submission-status,
delivery-event, or inbound-message contracts.
