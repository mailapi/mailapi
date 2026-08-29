---
title: "Microsoft Graph Mail crosswalk"
sidebar:
  label: Microsoft Graph
---

This crosswalk compares Mail API with the Microsoft Graph `sendMail` API
operation (`POST /users/{id}/sendMail` and `POST /me/sendMail`). Microsoft Graph
supports Microsoft 365, Exchange Online, and Outlook.com mailboxes. Like the
Gmail API, an adapter acts on behalf of an authorized mailbox or tenant; it is
not an account-wide, provider-neutral transactional-email API.

## References

- [Microsoft Graph `sendMail` reference](https://learn.microsoft.com/en-us/graph/api/user-sendmail?view=graph-rest-1.0):
  send endpoint, request payload, and `202 Accepted` response.
- [Microsoft Graph `message` resource type](https://learn.microsoft.com/en-us/graph/api/resources/message?view=graph-rest-1.0):
  structured message, recipient, and attachment representations.
- [Microsoft Graph error responses and codes](https://learn.microsoft.com/en-us/graph/errors):
  status codes, error codes, and retry guidance.

## Potential adapter boundary

The adapter converts an `OutboundMessageRequest` into a Microsoft Graph
`sendMail` JSON request. Microsoft Graph accepts a structured `message` object
and returns `202 Accepted` with an empty body on success.

| Mail API field | Microsoft Graph mapping | Notes |
| --- | --- | --- |
| `from` | `from` or `sender` | Expressed as a `recipient` object (`{"emailAddress": {"address": "...", "name": "..."}}`). Must match the authorized mailbox or a permitted send-as/send-on-behalf identity. |
| `to`, `cc`, `bcc` | `toRecipients`, `ccRecipients`, `bccRecipients` | Convert each `EmailAddress` into a Graph `recipient` object. |
| `replyTo` | `replyTo` | Array of `recipient` objects. |
| `subject` | `subject` | Direct correspondence. |
| `text`, `html` | `body` | Graph accepts a single body object (`{"contentType": "Text" \| "Html", "content": "..."}`). An adapter selects the HTML body when present, falling back to plain text. |
| `headers` | `internetMessageHeaders` | Graph's JSON form accepts only custom header names beginning with `x-`. Other supplemental RFC 5322 headers require the MIME request form or an explicit rejection or lossy-mapping policy. Structured fields take precedence. |
| `attachments` | `attachments` | Array of file attachment objects with `"@odata.type": "#microsoft.graph.fileAttachment"`, `name`, `contentType`, and Base64-encoded `contentBytes`. |
| submission `id` | Provider-generated Mail API ID | Microsoft Graph `sendMail` returns `202 Accepted` without a message ID; the adapter must mint the Mail API ID beforehand. |

Microsoft Graph's `sendMail` natively returns `202 Accepted`, which matches
Mail API's default asynchronous acceptance model. An adapter returns Mail API
`202` by default, or `200` if an applied wait covers completion of the Graph
API call. Neither status confirms final recipient delivery.

## Response and error mapping

Microsoft Graph returns standard HTTP status codes accompanied by an OData JSON
error object containing `code` and `message`.

Mail API's `401` and `403` describe the *caller's* credentials at the Mail API
boundary. If the adapter cannot authenticate to Microsoft Graph or lacks
delegated application permissions, the caller's request was still valid, so the
adapter returns `500`.

| Microsoft Graph result | Mail API response | Adapter handling |
| --- | --- | --- |
| `202 Accepted` | `202` by default; `200` after an applied wait | Return the minted Mail API submission `id`; this does not confirm delivery. |
| `400` `RequestBodyRead` or `InvalidRequest` | `500` or `422` | Treat serialization defects as `500`; map invalid semantic message content rejected by Graph to `422`. |
| `401` `InvalidAuthenticationToken` | `500` | Refresh or repair the adapter's OAuth token or client secret; do not expose Graph credentials to the caller. |
| `403` `ErrorSendAsDenied` | `403` | The authenticated principal lacks permission to send as the requested `from` address. |
| `403` `Authorization_RequestDenied` | `500` | The adapter's app registration lacks required Graph scopes (`Mail.Send`); repair tenant consent. |
| `404` `ResourceNotFound` or `ErrorItemNotFound` | `500` | The target mailbox or user principal does not exist in Microsoft Entra ID. |
| `429` or `503` `ActivityLimitReached` | `429` | Propagate `Retry-After` when present and apply backoff. |
| `5xx`, timeout, or connection failure | `500` | The outcome may be unknown. Preserve Mail API idempotency state and avoid duplicate submission without an explicit retry policy. |

## Differences and limits

- Microsoft Graph access requires Microsoft Entra ID (Azure AD) application
  registration with `Mail.Send` application permissions or delegated OAuth
  consent. Organization-wide mailbox access can be restricted via Exchange
  Application Access Policies.
- Graph's `body` property is single-valued: it does not hold simultaneous
  `text/plain` and `text/html` alternatives. Adapters mapping both bodies must
  select one representation (typically HTML) for submission.
- Graph's JSON request form accepts only `x-` custom Internet message headers.
  A Mail API request can contain other supplemental RFC 5322 headers, so an
  adapter must use Graph's MIME request form or document which headers it
  rejects or drops.
- Inline Base64 attachments in `sendMail` are limited to 3 MB by Microsoft
  Graph. Messages with larger attachments require an attachment upload session
  or draft-based composition workflow.
- Microsoft Graph provides extensive mailbox, folder, rule, and search APIs,
  which remain outside the scope of Mail API `v1` message submission.
