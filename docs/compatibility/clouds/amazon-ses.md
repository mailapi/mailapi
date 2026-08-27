---
title: "Amazon SES compatibility"
sidebar:
  label: Amazon SES
---

This assessment compares Mail API with Amazon Simple Email Service (SES) API
v2. An adapter receives an `OutboundMessageRequest`, calls SES `SendEmail`, and
normalizes an accepted SES response to Mail API's `200` response. It is an
adapter boundary, not a requirement that a Mail API provider use SES.

## References

- [SES `SendEmail` API reference](https://docs.aws.amazon.com/ses/latest/APIReference-V2/API_SendEmail.html):
  request fields, `200` response, and API errors.
- [How email sending works in Amazon SES](https://docs.aws.amazon.com/ses/latest/dg/send-email-concepts-process.html):
  provider acceptance and unknown-outcome retry risk.
- [Managing Amazon SES sending limits](https://docs.aws.amazon.com/ses/latest/dg/manage-sending-quotas.html):
  quotas and rate limits.

## Potential adapter boundary

SES supports Simple, Raw, and Templated message content. An adapter can use
Simple content for the standard Mail API fields or compose a MIME message and
use Raw content when it must preserve the complete message representation.

| Mail API field | SES `SendEmail` mapping | Notes |
| --- | --- | --- |
| `from` | `FromEmailAddress` | The sender identity must be verified or otherwise authorized by SES. |
| `to`, `cc`, `bcc` | `Destination.ToAddresses`, `CcAddresses`, `BccAddresses` | Preserve each recipient list. |
| `replyTo` | `ReplyToAddresses` | Preserve all reply-to addresses. |
| `subject`, `text`, `html` | `Content.Simple.Subject`, `Body.Text`, `Body.Html` | Supply a charset explicitly when the adapter needs one. |
| `headers`, `attachments` | `Content.Simple.Headers`, `Attachments`, or `Content.Raw` | Raw MIME is the fallback for features that Simple content cannot represent faithfully. |
| accepted response `id` | SES `MessageId` | Store a mapping if an application needs to correlate SES events. |

SES returns HTTP `200` with a `MessageId` after accepting a message. The
adapter reports that result as Mail API `200`; neither indicates final
recipient delivery. The two status codes agree because both mean acceptance at
the submission boundary; see the [rationale for `200`](/concepts/rationale/).

## Response and error mapping

SES status codes are provider-facing responses. The adapter consumes them and
returns a Mail API response; it must not expose AWS credentials or resource
configuration as a client error.

Mail API's `401` and `403` describe the *caller's* credentials at the Mail API
boundary. They are not a channel for the adapter's own AWS credentials: if the
adapter cannot authenticate to SES, the caller's request was still valid, so
the adapter returns `500`.

| SES result | Mail API response | Adapter handling |
| --- | --- | --- |
| `200` with `MessageId` | `200` | Return the `MessageId` as the accepted-message `id`. |
| `400` malformed request | `500` | Treat syntax or serialization errors in the generated SES request as adapter defects. |
| `400` unverified or unauthorized sender identity | `403` | The caller may not send as the requested `from` identity under the configured SES account. |
| `400` `MessageRejected` or invalid message content | `422` | The Mail API message is unacceptable under the selected SES provider policy. |
| `429` `TooManyRequestsException` | `429` | Apply backoff; include `Retry-After` only when the adapter can determine a wait period. |
| SES credentials, region, configuration-set, or account configuration failure | `500` | Treat this as adapter or deployment configuration, not caller input. |
| SES `5xx`, timeout, or connection failure | `500` | The submission outcome can be unknown; retry only under a duplicate-risk policy. |

Use `503` only when the adapter knows it did not submit the message and is
temporarily unable to accept it. Once a request may have reached SES, return
the unknown-outcome `500` contract instead.

## Differences and limits

- SES authentication, verified identities, sending authorization, regions,
  configuration sets, templates, and event destinations are deployment
  concerns outside Mail API `v1`.
- SES quotas are region-specific, apply to recipients as well as messages, and
  can result in rate limiting. An adapter must enforce its own submission
  policy and honor temporary failures.
- SES documents that, on rare occasions, a send request can return an error
  after SES accepted the message. A timeout or error therefore has an unknown
  outcome; automatic retries can create duplicates and require a caller policy.
- SES delivery events, bounces, complaints, and suppression lists are provider
  event mechanisms. They do not define Mail API inbound-message or delivery
  status endpoints.
