---
title: "Gmail API compatibility"
sidebar:
  label: Gmail API
---

This assessment compares Mail API with the Gmail API `users.messages.send`
operation. The Gmail API supports consumer Gmail and Google Workspace
mailboxes. A Mail API adapter must act on behalf of an authorized mailbox; it
is not a provider-neutral, account-wide transactional-email API.

## References

- [Gmail API sending guide](https://developers.google.com/workspace/gmail/api/guides/sending):
  raw MIME request construction.
- [`users.messages.send` reference](https://developers.google.com/workspace/gmail/api/reference/rest/v1/users.messages/send):
  send endpoint, response, and OAuth scopes.
- [Gmail API error handling](https://developers.google.com/workspace/gmail/api/guides/handle-errors):
  HTTP status codes, error reasons, and retry guidance.

## Potential adapter boundary

The Gmail API accepts an RFC 2822/MIME message in the `raw` field, encoded with
base64url. An adapter composes that MIME message from an
`OutboundMessageRequest`, calls `users.messages.send`, and maps the Mail API
submission `id` to the returned Gmail message `id`.

| Mail API field | Gmail MIME mapping | Notes |
| --- | --- | --- |
| `from` | `From` header | Must be the authorized mailbox or a permitted send-as identity. |
| `to`, `cc`, `bcc` | `To`, `Cc`, `Bcc` headers | Gmail derives recipients from these headers. |
| `replyTo` | `Reply-To` header | Preserve the address list. |
| `subject`, `text`, `html` | `Subject` and MIME body parts | Compose multipart alternatives when both bodies are present. |
| `headers` | Supplemental MIME headers | Structured Mail API fields remain authoritative. |
| `attachments` | MIME attachment parts | Encode each part according to MIME before base64url-encoding the complete message. |
| submission `id` | Provider-generated Mail API ID mapped to the Gmail message `id` | The Gmail ID is a mailbox-resource identifier and can arrive after the default Mail API response. |

A successful Gmail response means Gmail accepted the message for sending. An
adapter returns Mail API `202` by default, or `200` if an applied wait covers
completion of the Gmail call. It must not report final recipient delivery; see
the [bounded-wait rationale](/concepts/rationale/).

## Response and error mapping

Gmail HTTP codes describe the Gmail API call, rather than Mail API's public
contract. The adapter must inspect Gmail's error `reason`, not only its status
code: for example, `403` can mean either a permission problem or a rate limit.

Mail API's `401` and `403` describe the *caller's* credentials at the Mail API
boundary. They are not a channel for the adapter's own OAuth credentials: if
the adapter cannot authenticate to Gmail, the caller's request was still valid,
so the adapter returns `500`.

| Gmail result | Mail API response | Adapter handling |
| --- | --- | --- |
| `200` with a Gmail message resource | `202` by default; `200` after an applied wait | Retain the Mail API submission `id` and map it to the Gmail message `id`; neither is delivery confirmation. |
| `400` `badRequest` | `500` or `422` | Use `500` for malformed generated MIME/API input and `422` for a valid Mail API message Gmail rejects semantically. |
| `401` authentication failure | `500` | Refresh or repair the adapter's OAuth credentials; do not expose them to the Mail API caller. |
| `403` send-as identity permission failure | `403` | The selected mailbox cannot send as the requested `from` identity, so the caller is not authorized for this submission. |
| `403` domain-policy or OAuth-scope failure | `500` | Repair adapter authorization or Workspace administration; this is not caller input. |
| `403` quota reason, or `429` | `429` | Back off according to the provider guidance and any available retry delay. |
| `404` selected mailbox or adapter resource missing | `500` | Treat the configured Gmail account/resource as an adapter configuration failure. |
| `500`, `502`, `503`, `504`, timeout, or connection failure | `500` | The submission outcome can be unknown. A matching Mail API key replays the stored `500`; starting another execution requires a new key and a duplicate-risk policy. |

Gmail documents that its `200` response does not establish successful
end-to-end mail sending. Mail API's `200` and `202` likewise stop at the
submission boundary and do not form a delivery-status contract.

## Differences and limits

- Gmail API access requires OAuth consent with a Gmail sending scope. In Google
  Workspace, organization-wide impersonation additionally requires
  administrator configuration. Credential and consent management are outside
  Mail API `v1`.
- The selected mailbox and its permitted send-as identities constrain the
  sender. Mail API's `from` field alone cannot grant permission to send as an
  arbitrary address.
- Gmail message, thread, label, draft, and mailbox-history resources are
  mailbox features. They do not add Mail API submission-status, delivery-event,
  or inbound-message contracts.
- A timeout or failed request can leave submission outcome unknown. A client
  can protect a retry with Mail API's `Idempotency-Key`; without one, retry
  behavior must account for duplicate-message risk. Mail API `v1` has no
  submission-status lookup.
