---
title: "SendGrid crosswalk"
sidebar:
  label: SendGrid
---

This crosswalk compares Mail API with Twilio SendGrid's v3 Mail Send API. An
adapter receives an `OutboundMessageRequest`, calls `POST /v3/mail/send`, and
normalizes an accepted SendGrid result to Mail API's default `202` or
bounded-wait `200` response. It is an adapter boundary, not a requirement that
a Mail API provider use SendGrid.

SendGrid also answers an accepted submission with `202` and defines no
per-submission status resource. This aligns closely with Mail API's default
response; see the [bounded-wait rationale](/concepts/rationale/).

## References

- [SendGrid Mail Send v3 API reference](https://www.twilio.com/docs/sendgrid/api-reference/mail-send/mail-send):
  request fields, `202` response, and API errors.
- [SendGrid Event Webhook](https://www.twilio.com/docs/sendgrid/for-developers/tracking-events/event):
  asynchronous delivery, bounce, and engagement events.

## Potential adapter boundary

SendGrid's request body is structurally further from Mail API than the other
assessed providers, because one request can carry many messages. A
`personalizations` array holds a separate recipient set, and optional
substitutions, per entry. A Mail API submission is one message with one
submission `id`, so an adapter constructs exactly one personalization and
does not expose SendGrid's batching.

| Mail API field | SendGrid mapping | Notes |
| --- | --- | --- |
| `from` | `from` | An object with `email` and optional `name`, matching `EmailAddress`. |
| `to`, `cc`, `bcc` | `personalizations[0].to`, `.cc`, `.bcc` | Recipients live inside a personalization, not at the top level. |
| `replyTo` | `reply_to_list` | Map to the list form, not the single `reply_to`, because Mail API `replyTo` is a list. Sending both fields is invalid. |
| `subject` | `subject` | Direct correspondence. A personalization-level subject would override it, so an adapter should not set both. |
| `text`, `html` | `content` | An array of `{type, value}` ordered by increasing preference: `text/plain` before `text/html`. |
| `headers` | `headers` | An object, so repeated header names cannot be preserved without an explicit adapter policy. SendGrid also reserves several headers. |
| `attachments` | `attachments` | Map filename, MIME type, and Base64 `content`; enforce SendGrid attachment and message-size limits. |
| submission `id` | Provider-generated Mail API ID mapped to `X-Message-Id` after acceptance | The Mail API ID must exist before the default asynchronous response. |

## Response and error mapping

SendGrid status codes are provider-facing responses. The adapter consumes them
and returns a Mail API response; it must not expose SendGrid API keys or account
configuration as a client error.

Mail API's `401` and `403` describe the *caller's* credentials at the Mail API
boundary. They are not a channel for the adapter's own SendGrid API key: if the
adapter cannot authenticate to SendGrid, the caller's request was still valid,
so the adapter returns `500`.

| SendGrid result | Mail API response | Adapter handling |
| --- | --- | --- |
| `202` with an empty body and `X-Message-Id` | `202` by default; `200` after an applied wait | Retain the Mail API submission `id` and map it to the header value. Neither result confirms recipient delivery. |
| `400` malformed request | `500` | Treat syntax or serialization errors in the generated SendGrid request as adapter defects. |
| `400` or `403` unverified sender identity | `403` | The caller may not send as the requested `from` identity under the configured SendGrid account. |
| `400` provider validation failure | `422` | The Mail API message is unacceptable under the selected SendGrid provider policy. |
| `413` payload too large | `413` | Surface the size limit rather than retrying an unchanged request. |
| `401` or adapter API-key, sender-authentication, or account configuration failure | `500` | Treat this as adapter or deployment configuration, not caller input. |
| `429` | `429` | Apply backoff and propagate a `Retry-After` value when available. |
| SendGrid `5xx`, timeout, or connection failure | `500` | The submission outcome can be unknown. A matching Mail API key replays the stored `500`; starting another execution requires a new key and a duplicate-risk policy. |

Use `503` only when the adapter knows it did not submit the message and is
temporarily unable to accept it. Once a request may have reached SendGrid,
return the unknown-outcome `500` contract instead.

## Differences and limits

- SendGrid's Mail Send API has no idempotency-key mechanism. An adapter that
  honors Mail API's optional `Idempotency-Key` must implement retention,
  replay, and the `409` conflict cases itself. Unlike Resend, SendGrid cannot
  also suppress a repeated downstream call, so the adapter must persist its
  execution state before calling SendGrid and must not call it again after an
  unknown-outcome `500`. It must not derive a key from message content, because
  identical content can be a legitimate second submission.
- SendGrid reports delivery, bounce, and engagement outcomes asynchronously
  through the Event Webhook, which posts to a deployment-owned endpoint. That
  is not a status resource the send call points to, and Mail API `v1` defines
  no delivery-event or webhook contract.
- Attachments support `content_id` and an inline `disposition`. Mail API `v1`
  has no content-ID or inline-embed field, so an adapter needs an explicit
  policy, such as rejecting inline parts, rather than silently emitting broken
  HTML.
- `personalizations` substitutions, dynamic template data, `template_id`,
  `send_at` scheduling, `categories`, `custom_args`, `batch_id`, and the
  `asm`, `mail_settings`, and `tracking_settings` objects are provider
  features. They do not define Mail API `v1` fields, and an adapter that
  exposes any of them does so through `extensions`.
- Sender authentication, API-key scoping and rotation, IP pools, and subuser
  configuration are deployment concerns outside Mail API `v1`.
- Inbound mail arrives through SendGrid's separate Inbound Parse feature. Mail
  API `v1` defines no inbound retrieval or callback operation.
