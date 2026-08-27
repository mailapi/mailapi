---
title: "Scope and capabilities"
sidebar:
  label: Scope and capabilities
---

Mail API `v1` is a compact HTTP contract for submitting a structured email to
a provider. It is not a lossless Internet-message format, an SMTP relay
interface, or a mailbox-access protocol.

| Capability | Mail API `v1` | Boundary |
| --- | --- | --- |
| `from`, `to`, `cc`, `bcc`, `replyTo` | Supported | Structured address fields. At least one recipient across `to`, `cc`, and `bcc` is required for submission. |
| `subject`, `text`, `html` | Supported | One or both body representations are accepted; this is not a general MIME tree. |
| Simple attachments | Supported | Filename, media type, and Base64 content. Inline disposition and content ID are not modeled. |
| Idempotency | Supported | Optional, principal-scoped `Idempotency-Key` with a 24-hour retention period. |
| Asynchronous acceptance | Supported with HTTP `202` by default | A client can request bounded waiting with `Prefer: wait=N`; completed submission can then return `200`. Neither status confirms recipient delivery. |
| Transport envelope | Not supported | No separate SMTP reverse-path or envelope-recipient list. The provider derives its transport envelope from structured message fields. |
| Raw RFC 5322 message | Not supported | The API cannot submit or return an opaque, lossless Internet message. |
| General MIME tree | Not supported | Nested multiparts, encapsulated messages, arbitrary body parts, disposition, and content IDs are outside the portable model. |
| Multiple `From` authors and `Sender` | Not supported | `from` is one address; RFC 5322's multiple-author and responsible-sender distinction is not represented. |
| IMAP or POP3 abstraction | Not supported | No mailbox, maildrop, query, synchronization, flag, or deletion operation is defined. |
| Inbound message | Representation only | `InboundMessage` defines a data shape, but `v1` has no retrieval, webhook, or receiving operation. Lossless inbound mail may require a future raw-message model. |
| Submission-status resource | Not supported | The returned ID is a correlation identifier, not a promise of a status lookup. A future version may add status as a separate capability. |

## Compatibility does not expand the contract

The [compatibility assessments](/#compatibility-assessments) explain how
protocols, providers, libraries, and applications can map to this boundary.
They do not add fields or operations to Mail API. When a source has richer
semantics, an adapter must reject unsupported input, apply a documented lossy
transformation, or use a provider-specific `extensions` member where
appropriate.

The most consequential known gaps are the transport envelope and lossless raw
message handling. Their protocol rationale is documented in the
[SMTP](/compatibility/protocols/smtp/),
[JMAP](/compatibility/protocols/jmap/),
[IMAP](/compatibility/protocols/imap/), and
[POP3](/compatibility/protocols/pop/) assessments.

## Future capabilities

A future capability should be additive and should not change what an existing
`POST /v1/messages` success response means. Candidate capabilities include an
optional transport envelope, a raw-message or richer MIME representation,
inbound retrieval or webhooks, and a submission-status resource. Any adopted
change follows the [versioning policy](/concepts/versioning/).
