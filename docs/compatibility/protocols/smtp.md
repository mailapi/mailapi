---
title: "SMTP compatibility"
sidebar:
  label: SMTP
---

## Protocol role

SMTP transfers a message using a transport envelope and RFC 5322/MIME content.
Mail API defines an HTTP submission endpoint rather than an SMTP endpoint. An
SMTP-facing adapter can accept a transaction and call `POST /v1/messages`, but
Mail API `v1` cannot represent every SMTP transaction losslessly.

## References

- [RFC 5321: Simple Mail Transfer Protocol](https://www.rfc-editor.org/rfc/rfc5321.html):
  SMTP envelope, transaction, reply codes, and transfer responsibility.
- [RFC 6409: Message Submission for Mail](https://www.rfc-editor.org/rfc/rfc6409.html):
  the message-submission profile of SMTP.
- [RFC 4954: SMTP Service Extension for Authentication](https://www.rfc-editor.org/rfc/rfc4954.html):
  SMTP authentication and the `530` reply.
- [RFC 5322: Internet Message Format](https://www.rfc-editor.org/rfc/rfc5322.html):
  visible message fields, including `Bcc` handling.
- [RFC 2045: MIME Part One](https://www.rfc-editor.org/rfc/rfc2045.html):
  MIME bodies and transfer encoding.

## Potential adapter boundary

The adapter sees two independent inputs: `MAIL FROM` and accepted `RCPT TO`
commands form the SMTP envelope, while `DATA` contains the RFC 5322/MIME
message. The envelope controls actual delivery; visible destination headers do
not.

| SMTP concept | Mail API concept | Mapping and limit |
| --- | --- | --- |
| `MAIL FROM` reverse-path | — | No lossless mapping. It may be empty and may differ from the visible author; Mail API has no envelope-sender field. |
| accepted `RCPT TO` forward-paths | — | These are the actual recipients. Mail API has no envelope-recipient field independent of visible `to`, `cc`, and `bcc`. |
| `From` and `Sender` headers | `from` | Mail API can preserve one visible author only. RFC 5322 permits multiple authors and then requires a separate responsible `Sender`; neither that distinction nor the SMTP reverse-path fits this field. |
| `To` and `Cc` headers | `to`, `cc` | Preserve visible destination fields only. They may contain addresses that are not envelope recipients. |
| `Bcc` header | `bcc` | Available only if still present. RFC 5322 commonly removes this field before transfer, so it cannot recover blind envelope recipients. |
| `Reply-To` header | `replyTo` | Parse into an address list. |
| `Subject` header | `subject` | Decode and copy the field value. |
| `text/plain` and `text/html` MIME parts | `text`, `html` | Select and decode body alternatives. Nested or multiple alternatives may require a lossy policy. |
| Supplemental headers | `headers` | Preserve unfolded fields in order, excluding structured and MIME-framing fields forbidden by `OutboundMessageRequest`. |
| Regular MIME attachments | `attachments` | Decode bytes and preserve filename and media type. Inline disposition and content IDs have no portable mapping. |

For `multipart/alternative`, an adapter can preserve selected plain-text and
HTML alternatives. Other MIME trees require a documented transformation or
rejection policy.

## Submission and delivery boundary

An unrestricted SMTP relay adapter cannot safely infer Mail API recipients from
visible headers. Copying every visible `To`/`Cc` address may add recipients that
were not accepted with `RCPT TO`; ignoring envelope-only recipients may drop
blind copies. Until Mail API has explicit envelope fields, an adapter must
either reject transactions whose envelope differs from the derivation Mail API
would make or operate under a deployment policy that guarantees they match.

After accepting the complete SMTP transaction, a Mail API `200` can map to the
final SMTP `250` response when bounded waiting was applied: both mean the next
system accepted responsibility for further processing, not that recipients
received the message. A Mail API `202` is not yet sufficient for a final SMTP
`250`; an SMTP-facing adapter must keep the SMTP transaction open until the
Mail API execution reaches a terminal result or apply a transient-failure
policy.

| Mail API result | SMTP-facing result | Adapter policy |
| --- | --- | --- |
| `200` | `250` after message content | Accept the transaction; do not present this as final delivery. |
| `202` | no final reply yet | Continue waiting for terminal submission state; `202` alone does not establish the SMTP handoff result. |
| `400` or `415` | transient local failure, commonly `451` | A conforming adapter creates valid JSON with the correct media type, so these normally indicate an adapter defect rather than bad client content. |
| `413` | permanent size failure, commonly `552` | Reject the unchanged message because it exceeds a provider or adapter limit. |
| `422` | permanent content failure, commonly `554` | Reject semantically invalid message content. |
| `401` | deployment-defined local failure | The adapter normally owns the Mail API credential. Do not report its credential failure as an SMTP client's authentication failure unless the deployment explicitly shares that identity boundary. |
| `403` | permanent sender/submission failure, commonly `550` or `553` | Reject an identity or submission that the authenticated Mail API principal may not use. |
| in-progress `409`, `429`, `503` | transient `4xx` | Retry later; honor `Retry-After` internally when present. |
| reused-key `409` | local adapter failure | An SMTP client does not supply a Mail API idempotency key. A collision with a different body normally means the adapter reused its internal key incorrectly. |
| `500` or lost HTTP response | policy-dependent `4xx`/`5xx` | The outcome may be unknown. Preserve Mail API idempotency state and avoid a second execution unless duplicate risk is accepted. |

## Mail API implications

- The highest-priority gap is an optional transport envelope containing a
  nullable/empty reverse-path and one or more envelope recipients. When absent,
  the provider can continue deriving the envelope from structured message
  fields for backward compatibility.
- A complete envelope design must consider SMTPUTF8 addresses and optional DSN
  parameters; merely adding another display-address field would be
  insufficient.
- The message model should separately evaluate multiple `From` authors and the
  RFC 5322 `Sender` field; these are message-header concepts, not substitutes
  for the SMTP reverse-path.
- Lossless SMTP/MIME adaptation also needs raw RFC 5322 content or a richer MIME
  tree, including disposition and content ID. These additions should not make
  the compact structured request harder for ordinary HTTP clients.
- SMTP authentication, TLS, rate limits, and retry scheduling remain deployment
  concerns. The SMTP client's identity and the adapter's Mail API principal are
  not automatically the same security principal.
- SMTP has no application idempotency key. A robust bridge should accept and
  durably queue the SMTP transaction before calling Mail API, so SMTP retry and
  Mail API execution can be reconciled without deriving a key from message
  content or accidentally suppressing a legitimate identical message.
