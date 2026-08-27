---
title: "POP3 compatibility"
sidebar:
  label: POP3
---

Post Office Protocol version 3 (POP3) is a simple mail-access protocol for
retrieving messages from a server mailbox. It is a useful comparison point for
inbound mail, but it does not define message submission and it has no mailbox
hierarchy or synchronization model comparable to IMAP.

## References

- [RFC 1939: Post Office Protocol - Version 3](https://www.rfc-editor.org/rfc/rfc1939.html):
  POP3 retrieval, deletion, and message format.
- [RFC 6409: Message Submission for Mail](https://www.rfc-editor.org/rfc/rfc6409.html):
  the separate standard SMTP submission protocol.

## Potential adapter boundary

A POP3-to-Mail-API adapter can retrieve a complete RFC 5322/MIME message with
`RETR` and convert it to an `InboundMessage` representation. This is a data
mapping only: Mail API `v1` does not define an inbound retrieval endpoint,
maildrop, deletion operation, or delivery webhook.

| POP3 concept | Mail API concept | Mapping and limit |
| --- | --- | --- |
| `RETR` | `InboundMessage.message` | Parse the complete RFC 5322/MIME message into structured addresses, bodies, headers, and attachments. |
| `LIST` message size | — | No direct mapping; Mail API does not expose stored-message size metadata. |
| `UIDL` | `InboundMessage.id` | No direct mapping. A POP3 unique ID is maildrop-specific, not a Mail API message ID. |
| `DELE` and `QUIT` update | — | Out of scope; Mail API does not define deletion of received messages. |
| Server maildrop | — | Out of scope; Mail API does not model a mailbox or retained-message store. |
| `TOP` | — | Out of scope; Mail API does not define partial message retrieval. |

## Submission and delivery boundary

POP3 does not replace `POST /v1/messages`. A Mail API provider can use POP3
for inbound retrieval internally or offer it alongside its HTTP API, but that
is an implementation or deployment choice. Outbound submission belongs at the
Mail API HTTP boundary (or an SMTP submission adapter); retrieving a message
through POP3 does not confirm how or whether the provider delivered it.

## Difference from IMAP

POP3 is intentionally small: it retrieves messages from a single maildrop and
optionally deletes them after download. It does not define IMAP-style folders,
server-side search, flags, concurrent mailbox state, or synchronization. An
integration that needs those capabilities should use IMAP directly. Mail API
`v1` intentionally implements neither mail-access model.
