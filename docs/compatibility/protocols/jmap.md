---
title: "JMAP compatibility"
sidebar:
  label: JMAP
---

This assessment compares Mail API with the IETF JSON Meta Application Protocol
(JMAP). JMAP is a mail-store and submission protocol, not merely an outbound
transactional-email API: it synchronizes mailboxes and messages, supports push,
and submits an existing email for delivery.

## References

- [RFC 8620: JMAP Core](https://www.rfc-editor.org/rfc/rfc8620.html):
  session discovery, method calls, and generic synchronization model.
- [RFC 8620 section 3: The JMAP API](https://www.rfc-editor.org/rfc/rfc8620.html#section-3):
  the Request and Response objects, and the split between request-level and
  method-level errors.
- [RFC 8621: JMAP for Mail](https://www.rfc-editor.org/rfc/rfc8621.html):
  `Email`, `Identity`, `EmailSubmission`, mail access, and submission.
- [RFC 8621 section 7: Email submission](https://www.rfc-editor.org/rfc/rfc8621.html#section-7):
  the `EmailSubmission` object, including its `undoStatus` and
  `deliveryStatus` properties.
- [JMAP specifications](https://jmap.io/spec.html):
  current protocol specifications and extensions.

## Potential adapter boundary

A Mail API submission contains a complete structured message and returns a
single accepted-message ID. JMAP ordinarily creates or imports an `Email` into
a mailbox, then uses `EmailSubmission/set` to submit that existing `Email`
through a selected `Identity`. A JMAP adapter can perform those method calls
and return a Mail API `200` after the server accepts the submission.

JMAP itself answers a successful method batch with HTTP `200`. A method that
fails returns an `error` response object inside that same `200`; only a
request-level failure, such as an unparseable or unauthorized request, gets a
non-`2xx` HTTP status. State belongs to the objects: `EmailSubmission` carries
`undoStatus` for the submission's own lifecycle and an optional
`deliveryStatus` for per-recipient delivery. JMAP therefore keeps even
*delivery* state in a resource rather than in the HTTP status of the submit
call. Mail API makes the same division, which is part of the
[rationale for `200`](/concepts/rationale/).

| Mail API concept | JMAP equivalent | Notes |
| --- | --- | --- |
| `from` | `Identity` and Email sender fields | JMAP authorizes submission through a server-defined identity. |
| `to`, `cc`, `bcc`, `replyTo` | `Email` address fields | An adapter composes the JMAP email representation from structured addresses. |
| `subject`, `text`, `html`, attachments, headers | `Email` body structure and blobs | JMAP models mailbox email and binary data in more detail than Mail API `v1`. |
| accepted response `id` | `EmailSubmission` ID | Keep the JMAP email and submission IDs internal unless the adapter documents one as the Mail API ID. |
| incoming message representation | `Email` in a mailbox | JMAP has standardized query, changes, and push semantics that Mail API `v1` does not define. |

## Differences and limits

- JMAP's method-response envelope and per-method error objects are not a direct
  HTTP-status mapping: an adapter cannot forward JMAP's HTTP status, because a
  failed `EmailSubmission/set` arrives inside a `200`. It must inspect the
  method response and normalize both error levels to the public `200` and
  problem-details responses.
- JMAP submission includes mailbox placement, drafts, identities, and a
  separate `EmailSubmission` lifecycle. Mail API intentionally exposes only a
  compact send boundary and no mailbox model.
- JMAP offers standardized inbound mailbox access and synchronization. This is
  a useful future reference for Mail API inbound and status capabilities, but
  it does not add endpoints to Mail API `v1`.
