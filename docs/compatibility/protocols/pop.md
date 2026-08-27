---
title: "POP3 compatibility"
sidebar:
  label: POP3
---

## Protocol role

Post Office Protocol version 3 (POP3) is a simple, stateful mail-access
protocol for listing, retrieving, and optionally deleting messages from one
maildrop. It does not define message submission, folders, flags, server-side
search, push, or an IMAP-style synchronization model.

## References

- [RFC 1939: Post Office Protocol - Version 3](https://www.rfc-editor.org/rfc/rfc1939.html):
  POP3 states, retrieval, deletion, and message format.
- [RFC 1939 section 7](https://www.rfc-editor.org/rfc/rfc1939.html#section-7):
  optional commands, including `TOP` and `UIDL`.
- [RFC 6409: Message Submission for Mail](https://www.rfc-editor.org/rfc/rfc6409.html):
  the separate SMTP submission protocol.

## Potential adapter boundary

A POP3 adapter can retrieve a complete RFC 5322/MIME message with `RETR` and
create an `InboundMessage`. This is a representation mapping only: Mail API
`v1` defines no inbound retrieval, maildrop, deletion, or webhook operation.

| POP3 concept | Mail API concept | Mapping and limit |
| --- | --- | --- |
| `RETR` | `InboundMessage.message` | Parse the complete message. The mapping can be lossy because Mail API has no raw-message field and flattens MIME structure. |
| `LIST` size | — | Mail API does not expose stored-message size metadata. |
| optional `UIDL` | Source correlation | The unique ID persists across sessions and identifies a message within one maildrop, so it can support download tracking. It is not a global Mail API ID, and identical copies may share an ID. |
| `DELE`, `RSET`, and the `QUIT` update | — | Deletion is session state and normally takes effect when the session enters the update state; Mail API has no equivalent mutation. |
| optional `TOP` | — | Retrieves headers plus a requested number of body lines. Mail API does not define partial retrieval. |
| server maildrop | — | Mail API does not model a retained-message store. |

POP3 provides no standard receipt timestamp corresponding to
`InboundMessage.receivedAt`. An adapter must obtain that value from provider
metadata or define its own ingestion-time policy; it cannot derive it from
`RETR`, `LIST`, or `UIDL`.

## Submission and delivery boundary

POP3 does not replace `POST /v1/messages`. A provider may use POP3 for inbound
ingestion while using Mail API or SMTP submission for outbound mail. Retrieving
a message does not confirm how or whether it was delivered to any other
recipient.

## Mail API implications

- As with IMAP, arbitrary stored RFC 5322/MIME messages cannot always fit the
  required and flattened `InboundMessage.message` schema.
- A future inbound contract should distinguish a provider-assigned Mail API ID
  from optional source identifiers such as maildrop plus `UIDL`.
- Raw-message preservation would avoid losing MIME structure and headers. POP3
  itself offers no basis for mailbox hierarchy, push, or delivery status, so
  those capabilities should not be inferred from a POP3 adapter.
