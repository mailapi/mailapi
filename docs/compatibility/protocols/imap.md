---
title: "IMAP compatibility"
sidebar:
  label: IMAP
---

IMAP4rev2 is a mail-access protocol: clients use it to access and manipulate
messages and mailboxes on a server. It is an essential comparison point for
inbound mail, but it is not a message-submission protocol. IMAP4rev2 explicitly
leaves posting mail to a mail-submission protocol.

## References

- [RFC 9051: IMAP4rev2](https://www.rfc-editor.org/rfc/rfc9051.html):
  mailbox access, message retrieval, synchronization, and the boundary with
  mail submission.
- [RFC 6409: Message Submission for Mail](https://www.rfc-editor.org/rfc/rfc6409.html):
  the standard SMTP submission protocol referenced by IMAP4rev2.

## Potential adapter boundary

An IMAP-to-Mail-API adapter can fetch a message and convert its RFC 5322/MIME
content into an `InboundMessage` representation. This is a representation
mapping only: Mail API `v1` does not currently define an inbound retrieval,
mailbox, synchronization, or webhook endpoint.

| IMAP concept | Mail API concept | Mapping and limit |
| --- | --- | --- |
| `FETCH` message headers and body sections | `InboundMessage.message` | Parse RFC 5322/MIME content into structured addresses, bodies, headers, and attachments. |
| `INTERNALDATE` | `InboundMessage.receivedAt` | A provider may use it as received metadata, subject to its documented policy. |
| UID and `UIDVALIDITY` | `InboundMessage.id` | No direct mapping. IMAP mailbox-scoped identifiers and validity epochs are not Mail API message IDs. |
| Mailboxes, `SELECT`, `LIST`, and subscriptions | — | Out of scope; Mail API does not model mailboxes or folders. |
| `SEARCH`, `SORT`, flags, `STORE`, `MOVE`, and `EXPUNGE` | — | Out of scope; Mail API does not define mailbox query or mutation operations. |
| `IDLE` and resynchronization | — | Out of scope; Mail API does not define change streams, push, or synchronization state. |
| `APPEND` | — | `APPEND` stores a message in a mailbox; it is not recipient delivery or Mail API submission. |

## Submission and delivery boundary

IMAP does not replace `POST /v1/messages`. A Mail API provider can use IMAP for
inbound retrieval internally or offer IMAP alongside its HTTP API, but that is
an implementation or deployment choice. Outbound submission belongs at the
Mail API HTTP boundary (or an SMTP submission adapter), while recipient
delivery remains asynchronous and is not confirmed by either API's acceptance.

## Why Mail API remains smaller

IMAP includes persistent connection state, mailbox hierarchy, message flags,
partial MIME retrieval, searches, and synchronization. Those capabilities are
needed by mail clients, whereas Mail API focuses on a small, provider-neutral
contract for message submission and received-message representation. An
integration that needs mailbox access should use IMAP directly; it should not
expect Mail API `v1` to emulate IMAP.
