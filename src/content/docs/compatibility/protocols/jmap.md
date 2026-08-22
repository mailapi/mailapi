---
title: "JMAP compatibility"
---

This assessment compares Mail API with the IETF JSON Meta Application Protocol
(JMAP). JMAP is a mail-store and submission protocol, not merely an outbound
transactional-email API: it synchronizes mailboxes and messages, supports push,
and submits an existing email for delivery.

## References

- [RFC 8620: JMAP Core](https://www.rfc-editor.org/rfc/rfc8620.html) — session discovery, method calls, and generic synchronization model.
- [RFC 8621: JMAP for Mail](https://www.rfc-editor.org/rfc/rfc8621.html) — `Email`, `Identity`, `EmailSubmission`, mail access, and submission.
- [JMAP specifications](https://jmap.io/spec.html) — current protocol specifications and extensions.

## Potential adapter boundary

A Mail API submission contains a complete structured message and returns a
single accepted-message ID. JMAP ordinarily creates or imports an `Email` into
a mailbox, then uses `EmailSubmission/set` to submit that existing `Email`
through a selected `Identity`. A JMAP adapter can perform those method calls
and return a Mail API `200` after the server accepts the submission.

| Mail API concept | JMAP equivalent | Notes |
| --- | --- | --- |
| `from` | `Identity` and Email sender fields | JMAP authorizes submission through a server-defined identity. |
| `to`, `cc`, `bcc`, `replyTo` | `Email` address fields | An adapter composes the JMAP email representation from structured addresses. |
| `subject`, `text`, `html`, attachments, headers | `Email` body structure and blobs | JMAP models mailbox email and binary data in more detail than Mail API `v1`. |
| accepted response `id` | `EmailSubmission` ID | Keep the JMAP email and submission IDs internal unless the adapter documents one as the Mail API ID. |
| incoming message representation | `Email` in a mailbox | JMAP has standardized query, changes, and push semantics that Mail API `v1` does not define. |

## Differences and limits

- JMAP's method-response envelope and per-method error objects are not a direct
  HTTP-status mapping. A Mail API adapter normalizes them to the public `200`
  and problem-details responses.
- JMAP submission includes mailbox placement, drafts, identities, and a
  separate `EmailSubmission` lifecycle. Mail API intentionally exposes only a
  compact send boundary and no mailbox model.
- JMAP offers standardized inbound mailbox access and synchronization. This is
  a useful future reference for Mail API inbound and status capabilities, but
  it does not add endpoints to Mail API `v1`.
