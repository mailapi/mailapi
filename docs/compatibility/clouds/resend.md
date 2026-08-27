---
title: "Resend compatibility"
sidebar:
  label: Resend
---

This assessment compares Mail API with Resend's Email API. An adapter converts
an `OutboundMessageRequest` to Resend `POST /emails`, then normalizes a
successful Resend result to Mail API's default `202` or bounded-wait `200`
response. It does not require a Mail API provider to use Resend.

## References

- [Resend send-email reference](https://resend.com/docs/api-reference/emails/send-email):
  request fields, `200` response, email ID, and `Idempotency-Key`.
- [Resend API introduction](https://resend.com/docs/api-reference/introduction):
  standard API error status codes.
- [Resend usage limits](https://resend.com/docs/api-reference/rate-limit):
  `429` and rate-limit response headers, including `retry-after`.

## Potential adapter boundary

Resend's send-email request directly represents most Mail API message fields.
The adapter maps the accepted Resend email `id` to the Mail API submission
identifier. It returns Mail API `202` by default, or `200` if an applied wait
covers completion of the Resend call. Neither response confirms final recipient
delivery; see the [bounded-wait rationale](/concepts/rationale/).

| Mail API field | Resend mapping | Notes |
| --- | --- | --- |
| `from` | `from` | Format the display name and email address as a mailbox string. |
| `to`, `cc`, `bcc` | `to`, `cc`, `bcc` | Convert address objects to mailbox strings. |
| `replyTo` | `reply_to` | Convert the address list to the provider representation. |
| `subject`, `text`, `html` | `subject`, `text`, `html` | Preserve both body alternatives when provided. |
| `headers` | `headers` | Resend custom headers are an object, so repeated header names cannot be preserved without an explicit adapter policy. |
| `attachments` | `attachments` | Map filename and Base64 content; enforce Resend attachment limits. |
| `Idempotency-Key` request header | Adapter idempotency record and Resend `Idempotency-Key` | Scope the client key to the authenticated Mail API principal. Persist a separate opaque downstream key for the Resend call; do not forward a multi-tenant client key unchanged. |
| submission `id` | Provider-generated Mail API ID mapped to the Resend email `id` | The Mail API ID must exist before the default asynchronous response. |

## Response and error mapping

Resend status codes are provider-facing responses. The adapter converts them to
Mail API's public contract and must not expose Resend API keys or account
configuration to the caller.

Mail API's `401` and `403` describe the *caller's* credentials at the Mail API
boundary. They are not a channel for the adapter's own Resend API key: if the
adapter cannot authenticate to Resend, the caller's request was still valid, so
the adapter returns `500`.

| Resend result | Mail API response | Adapter handling |
| --- | --- | --- |
| `200` with an email `id` | `202` by default; `200` after an applied wait | Retain the Mail API submission `id` and store its mapping to the Resend ID. |
| `400` malformed request | `500` | Treat invalid generated Resend request syntax or serialization as an adapter defect. |
| `400` unverified or unauthorized sending domain | `403` | The caller may not send as the requested `from` identity under the configured Resend account. |
| `400` provider validation failure | `422` | The Mail API message is unacceptable under the selected Resend provider policy. |
| Local idempotency conflict | `409` | The adapter, not Resend, preserves the Mail API distinction between a different payload and an in-progress matching execution. |
| `401`, `403`, or provider domain/account configuration failure | `500` | Repair adapter credentials, authorization, or Resend account configuration. |
| `429` | `429` | Apply backoff and propagate a `Retry-After` value when available. |
| Resend `5xx`, timeout, or connection failure | `500` | The submission outcome can be unknown. A matching Mail API key replays the stored `500`; starting another execution requires a new key and a duplicate-risk policy. |

Use `503` only when the adapter knows it did not submit the message and is
temporarily unable to accept it. Once a request may have reached Resend, return
the unknown-outcome `500` contract instead.

## Idempotency and provider features

Resend supports an `Idempotency-Key` request header that prevents duplicate
emails for 24 hours, but that mechanism alone does not implement the complete
Mail API contract. A Mail API adapter must own the principal-scoped key record,
the exact-body comparison, the in-progress state, non-terminal `202` handling,
and replay of stored terminal `200` and `500` responses.

For the downstream Resend request, the adapter creates an opaque key unique to
the local idempotency record and persists it before calling Resend. It reuses
that downstream key only when recovering the same execution. It must not
forward the caller's key unchanged when multiple Mail API principals can share
one Resend account, and it must not derive a key from message content because
identical content can be a legitimate second submission.

Resend can retrieve sent-email records and their latest provider event. Those
records, delivery events, templates, tags, scheduling, and API-key management
are provider features; they do not define Mail API `v1` submission-status,
delivery-event, or inbound-message contracts.
