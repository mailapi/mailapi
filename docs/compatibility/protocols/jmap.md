---
title: "JMAP compatibility"
sidebar:
  label: JMAP
---

## Protocol role

JMAP is an HTTP/JSON protocol for mail-store access, synchronization, push, and
submission. Unlike Mail API's one-shot send request, JMAP submits an existing
`Email` through an `Identity` by creating an `EmailSubmission` object.

## References

- [RFC 8620: JMAP Core](https://www.rfc-editor.org/rfc/rfc8620.html):
  session discovery, method calls, errors, and synchronization.
- [RFC 8620 section 3.6](https://www.rfc-editor.org/rfc/rfc8620.html#section-3.6):
  request-level and method-level errors.
- [RFC 8621: JMAP for Mail](https://www.rfc-editor.org/rfc/rfc8621.html):
  `Email`, `Identity`, and mail access.
- [RFC 8621 section 7](https://www.rfc-editor.org/rfc/rfc8621.html#section-7):
  `EmailSubmission`, its SMTP envelope, lifecycle, and delivery status.

## Potential adapter boundary

For a new message, an adapter creates the JMAP `Email` and then creates an
`EmailSubmission` that references it. JMAP back-references allow dependent
method calls in one JMAP request when supported by the relevant methods. The
adapter treats submission as complete only after `EmailSubmission/set` reports
a successful creation. It returns Mail API `200` when an applied wait covers
that completion; otherwise Mail API returns the default `202` while the adapter
continues asynchronously.

| Mail API concept | JMAP equivalent | Mapping and limit |
| --- | --- | --- |
| `from` | `Email.from`, `Email.sender`, and `Identity` | The visible authors, responsible sender, and authorized submission identity are distinct. Mail API's single `from` address cannot represent every JMAP/RFC 5322 combination. |
| `to`, `cc`, `bcc`, `replyTo` | `Email` address fields | These represent RFC 5322 message fields. JMAP removes `Bcc` during delivery. |
| No explicit transport envelope | `EmailSubmission.envelope` | JMAP can supply `mailFrom`, `rcptTo`, and SMTP parameters explicitly, or let the server derive them from message fields. Mail API cannot express the explicit form. |
| `subject`, bodies, attachments, headers | `Email` body structure and blobs | JMAP preserves nested body structure and binary blobs more precisely than Mail API's flattened model. |
| submission `id` | Provider-generated Mail API ID mapped to the `EmailSubmission` ID | The Mail API ID exists before asynchronous execution; the referenced JMAP Email ID is separate. |
| `InboundMessage.receivedAt` | `Email.receivedAt` | Direct conceptual correspondence, subject to the JMAP server's stored metadata. |
| No status resource | `undoStatus` and optional `deliveryStatus` | JMAP can expose cancellation state and known per-recipient SMTP or DSN status; Mail API `v1` cannot. |

## Submission and delivery boundary

JMAP normally returns HTTP `200` for a syntactically valid JMAP request. A
failed method call is represented by an `error` item in `methodResponses`, not
by an HTTP error status. An adapter must inspect both HTTP-level failures and
method responses, then translate them to Mail API problem responses.

Creating an `EmailSubmission` means the message will be sent to its envelope
recipients. It does not mean final delivery has occurred. `undoStatus` describes
whether submission can still be canceled, while `deliveryStatus` is optional
and reports only status known to the server.

## Mail API implications

- JMAP confirms that visible address fields and the SMTP envelope are separate
  interoperable concepts. Mail API cannot faithfully adapt a supplied JMAP
  envelope when it differs from `From`/`To`/`Cc`/`Bcc`.
- JMAP also preserves multiple authors and a separate responsible sender. A
  future message model should decide whether to add `sender` and make `from` a
  list rather than silently selecting one address.
- JMAP's body structure highlights Mail API gaps for inline content IDs,
  disposition, nested multipart content, and lossless raw-message handling.
- `EmailSubmission` is a useful model for a future optional submission-status
  resource, but adding mailbox, undo, or delivery-status operations should be a
  separate capability rather than changing the meaning of `POST /v1/messages`.
