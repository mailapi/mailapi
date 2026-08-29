---
title: "IMAP crosswalk"
sidebar:
  label: IMAP
---

## Protocol role

IMAP4rev2 is a stateful mail-access protocol. It lets a client access and
manipulate messages and mailboxes, fetch complete messages or selected MIME
parts, maintain flags, search, and resynchronize offline state. It does not
post mail; RFC 9051 assigns that function to a separate submission protocol.

## References

- [RFC 9051: IMAP4rev2](https://www.rfc-editor.org/rfc/rfc9051.html):
  mailbox access, message attributes, synchronization, and commands.
- [RFC 9051 section 2.3.3](https://www.rfc-editor.org/rfc/rfc9051.html#section-2.3.3):
  `INTERNALDATE` semantics.
- [RFC 6409: Message Submission for Mail](https://www.rfc-editor.org/rfc/rfc6409.html):
  the separate SMTP submission protocol referenced by IMAP4rev2.

## Potential adapter boundary

An IMAP adapter can fetch an RFC 5322/MIME message and create an
`InboundMessage`. This is a representation mapping only: Mail API `v1` defines
no inbound retrieval, mailbox, synchronization, or webhook operation.

| IMAP concept | Mail API concept | Mapping and limit |
| --- | --- | --- |
| `FETCH BODY[]` | `InboundMessage.message` | Parse the complete RFC 5322/MIME message. This can be lossy because Mail API has no raw-message field and flattens MIME structure. |
| `ENVELOPE` and `BODYSTRUCTURE` | Structured message fields | Useful parsed views, but `ENVELOPE` represents RFC 5322 headers rather than the SMTP envelope, and neither item alone preserves the complete message. |
| `INTERNALDATE` | `InboundMessage.receivedAt` | Suitable when the provider documents that it uses IMAP's internal date. For SMTP-delivered mail it reflects final delivery; `APPEND`, `COPY`, and `MOVE` have separate rules. |
| mailbox name, `UIDVALIDITY`, and UID | Source correlation | Together they identify an IMAP message version within a mailbox. A UID alone is not a globally stable Mail API ID. |
| `RFC822.SIZE` | — | Mail API does not expose stored-message size metadata. |
| flags, keywords, `STORE`, `MOVE`, and `EXPUNGE` | — | Mail API does not model mailbox state or mutation. |
| `SEARCH`, `ESEARCH`, `IDLE`, and resynchronization state | — | Mail API does not define queries, change streams, or synchronization tokens. |
| `APPEND` | — | Stores a message in a mailbox; it is not submission for delivery. It may also store drafts that omit normally required RFC 5322 fields. |

## Submission and delivery boundary

IMAP does not replace `POST /v1/messages`. A provider may use IMAP for mailbox
access or inbound ingestion while using Mail API or SMTP submission for
outbound mail. Fetching a stored message says nothing about whether a prior
submission reached its recipients.

## Mail API implications

- `InboundMessage.message` requires `from`, but IMAP can contain drafts,
  malformed mail, and imported messages without that field. A general IMAP
  bridge therefore cannot represent every stored message.
- Nested multiparts, inline parts, encapsulated `message/rfc822` content, and
  unknown MIME types do not round-trip through Mail API's flattened
  `text`/`html`/`attachments` model.
- A future inbound contract should consider preserving raw RFC 5322 bytes and
  source metadata separately from normalized fields. Mailbox and synchronization
  operations should remain a separate capability rather than being inferred
  from `InboundMessage`.
