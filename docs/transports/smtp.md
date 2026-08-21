# SMTP transport compatibility

Mail API defines an HTTP submission endpoint; it does not define an SMTP
endpoint. An SMTP-based application needs an adapter or relay that accepts an
SMTP message, converts it to an `OutboundMessageRequest`, and submits it to
`POST /v1/messages`. Conversely, a Mail API provider may use SMTP internally
for delivery, but that implementation detail is outside this specification.

## MIME message mapping

The adapter parses the SMTP message's RFC 5322/MIME content and maps it to the
HTTP request.

| SMTP data | Mail API field | Mapping |
| --- | --- | --- |
| `From` header | `from` | Parse the visible author address and display name. Reject the submission if it is absent. |
| `To`, `Cc`, and `Bcc` headers | `to`, `cc`, `bcc` | Parse structured recipient headers into address lists. |
| `Reply-To` header | `replyTo` | Parse into an address list. |
| `Subject` header | `subject` | Decode and copy the header value. |
| `text/plain` MIME part | `text` | Decode the selected plain-text part. |
| `text/html` MIME part | `html` | Decode the selected HTML part. |
| Other headers | `headers` | Preserve supplemental and repeated fields in their original order. |
| Regular MIME attachments | `attachments` | Decode each body part, Base64-encode its bytes, and retain filename and media type. |

For `multipart/alternative`, preserve both selected `text/plain` and `text/html`
parts when available. Structured Mail API fields are authoritative, so an
adapter must not duplicate `From`, `To`, `Cc`, `Bcc`, `Reply-To`, or `Subject`
in `headers`.

## Envelope and delivery differences

SMTP's `MAIL FROM` and `RCPT TO` commands describe the delivery envelope; they
are not necessarily the same as the visible message headers. Mail API `v1` has
no separate envelope-sender field.

- Use the MIME `From` header for `from`, not `MAIL FROM`.
- An adapter must define a policy for envelope recipients that are absent from
  visible `To` or `Cc` headers. They are often Bcc recipients, but cannot be
  identified reliably after a message has been composed.
- A Mail API `202` can be translated to SMTP `250` acceptance. HTTP failures
  need an adapter-specific transient (`4xx`) or permanent (`5xx`) SMTP response
  policy; neither result confirms final recipient delivery.

## Unsupported or policy-dependent content

- Inline MIME attachments using content IDs have no Mail API `v1` equivalent.
  The adapter should reject them or define a documented transformation rather
  than send HTML with broken `cid:` references.
- SMTP authentication, TLS, client identity, retry behavior, size limits, and
  rate limits are deployment concerns. They are not defined by Mail API.
- Inbound Mail API examples are received-message data representations only;
  they do not define an SMTP receiving service or webhook endpoint.
