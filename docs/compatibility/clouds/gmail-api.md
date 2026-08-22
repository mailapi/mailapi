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

- [Gmail API sending guide](https://developers.google.com/workspace/gmail/api/guides/sending) — raw MIME request construction.
- [`users.messages.send` reference](https://developers.google.com/workspace/gmail/api/reference/rest/v1/users.messages/send) — send endpoint, response, and OAuth scopes.
- [Gmail API error handling](https://developers.google.com/workspace/gmail/api/guides/handle-errors) — HTTP status codes, error reasons, and retry guidance.

## Potential adapter boundary

The Gmail API accepts an RFC 2822/MIME message in the `raw` field, encoded with
base64url. An adapter composes that MIME message from an
`OutboundMessageRequest`, calls `users.messages.send`, and maps the returned
Gmail message `id` to Mail API's accepted-message identifier.

| Mail API field | Gmail MIME mapping | Notes |
| --- | --- | --- |
| `from` | `From` header | Must be the authorized mailbox or a permitted send-as identity. |
| `to`, `cc`, `bcc` | `To`, `Cc`, `Bcc` headers | Gmail derives recipients from these headers. |
| `replyTo` | `Reply-To` header | Preserve the address list. |
| `subject`, `text`, `html` | `Subject` and MIME body parts | Compose multipart alternatives when both bodies are present. |
| `headers` | Supplemental MIME headers | Structured Mail API fields remain authoritative. |
| `attachments` | MIME attachment parts | Encode each part according to MIME before base64url-encoding the complete message. |
| accepted response `id` | Gmail message `id` | This is a mailbox-resource identifier, not a delivery-status API. |

A successful Gmail response means Gmail accepted the message for sending. An
adapter maps that to Mail API `200`; it must not report final recipient
delivery.

## Response and error mapping

Gmail HTTP codes describe the Gmail API call, rather than Mail API's public
contract. The adapter must inspect Gmail's error `reason`, not only its status
code: for example, `403` can mean either a permission problem or a rate limit.

| Gmail result | Mail API response | Adapter handling |
| --- | --- | --- |
| `200` with a Gmail message resource | `200` | Return the Gmail message `id` as the accepted-message `id`; do not treat it as delivery confirmation. |
| `400` `badRequest` | `500` or `422` | Use `500` for malformed generated MIME/API input and `422` for a valid Mail API message Gmail rejects semantically. |
| `401` authentication failure | `500` | Refresh or repair the adapter's OAuth credentials; do not expose them to the Mail API caller. |
| `403` send-as identity permission failure | `422` | The selected mailbox cannot send as the requested `from` identity. |
| `403` domain-policy or OAuth-scope failure | `500` | Repair adapter authorization or Workspace administration; this is not caller input. |
| `403` quota reason, or `429` | `429` | Back off according to the provider guidance and any available retry delay. |
| `404` selected mailbox or adapter resource missing | `500` | Treat the configured Gmail account/resource as an adapter configuration failure. |
| `500`, `502`, `503`, `504`, timeout, or connection failure | `500` | The submission outcome can be unknown; retry only under a duplicate-risk policy. |

Gmail documents that a `200` response does not establish successful end-to-end
mail sending. This is compatible with Mail API `200`, which confirms provider
acceptance rather than recipient delivery, but it is not a delivery-status
contract.

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
