---
title: "Azure Communication Services Email compatibility"
sidebar:
  label: Azure Communication Services Email
---

This assessment compares Mail API with Azure Communication Services Email. An
adapter converts an `OutboundMessageRequest` into an Azure email send request,
then normalizes the accepted operation to a Mail API `200` response. It does
not require a Mail API provider to use Azure.

## References

- [Azure Email Send REST API](https://learn.microsoft.com/en-us/rest/api/communication/email/email/send?view=rest-communication-email-2025-09-01):
  `202 Accepted`, operation ID, and `Operation-Location`.
- [Azure Email get-send-result REST API](https://learn.microsoft.com/en-us/rest/api/communication/email/email/get-send-result?view=rest-communication-email-2025-09-01):
  operation-state polling and `Retry-After`.
- [Azure email sending quickstart](https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/email/send-email):
  SDK model and delivery boundary.
- [Azure Email Event Grid events](https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/email/handle-email-events):
  delivery and engagement events.

## Potential adapter boundary

Azure starts email sending as a long-running operation. The adapter submits the
request, maps the returned operation ID to Mail API's accepted-message `id`,
and returns `200` without waiting for delivery. Azure is the one assessed
provider that answers with `202`, and it earns that code by also exposing an
operation resource to poll. Mail API defines no such resource, which is part of
the [rationale for `200`](/concepts/rationale/).

| Mail API field | Azure Email mapping | Notes |
| --- | --- | --- |
| `from` | `senderAddress` | Must use a verified Azure Email domain sender. |
| `to`, `cc`, `bcc` | `recipients.to`, `cc`, `bcc` | Preserve each recipient list. |
| `replyTo` | `replyTo` | Preserve the address list. |
| `subject`, `text`, `html` | `content.subject`, `plainText`, `html` | At least one body representation is required by Azure. |
| `headers` | Custom headers | Preserve supplemental headers permitted by Azure. |
| `attachments` | Attachments | Convert Base64 content to Azure attachment data. |
| accepted response `id` | Azure operation ID | This identifies the send operation, not final recipient delivery. |

Azure's operation result can later be `Running`, `Succeeded`, or `Failed`.
That provider status is not a Mail API `v1` submission-status endpoint.
`Succeeded` means the message is out for delivery, not that a recipient has
received it.

## Response and error mapping

Azure status codes are provider-facing responses. The adapter converts them to
Mail API's public contract and must not expose Azure credentials or resource
configuration to the caller.

Mail API's `401` and `403` describe the *caller's* credentials at the Mail API
boundary. They are not a channel for the adapter's own Azure credentials: if
the adapter cannot authenticate to Azure, the caller's request was still valid,
so the adapter returns `500`.

| Azure result | Mail API response | Adapter handling |
| --- | --- | --- |
| `202 Accepted` with `Operation-Location` and an operation ID | `200` | Return the operation ID as the accepted-message `id`. The Mail API response has no counterpart to `Operation-Location`. |
| `400` malformed request | `500` | Treat invalid generated Azure request syntax or serialization as an adapter defect. |
| `400` unverified or unauthorized sender domain | `403` | The caller may not send as the requested `from` identity under the configured Azure resource. |
| `400` invalid recipient, content, or attachment | `422` | The Mail API message is unacceptable under the selected Azure provider policy. |
| `401`, `403`, or missing Azure resource caused by adapter configuration | `500` | Repair credentials, permissions, or Azure resource configuration. |
| `429` | `429` | Apply backoff; preserve a provider retry delay when available. |
| Azure `5xx`, timeout, or connection failure | `500` | The submission outcome can be unknown; retry only under a duplicate-risk policy. |

Use `503` only when the adapter knows it did not submit the message and is
temporarily unable to accept it. Once a request may have reached Azure, return
the unknown-outcome `500` contract instead.

## Differences and limits

- Azure Email authentication, verified domains, Communication Services
  resources, quotas, and custom-header restrictions are deployment concerns
  outside Mail API `v1`.
- Azure exposes operation polling through a separate send-result endpoint. Mail
  API `v1` deliberately has no submission-status lookup, so an adapter must not
  imply that the returned `id` supports such a lookup.
- Delivery reports and engagement reports are emitted through Azure Event Grid.
  They are provider events and do not define Mail API inbound-message or
  delivery-event contracts.
- A timeout after Azure receives a request can leave the outcome unknown. A
  client can protect a retry with Mail API's `Idempotency-Key`; without one,
  retry behavior requires a caller policy that accepts duplicate-message risk.
