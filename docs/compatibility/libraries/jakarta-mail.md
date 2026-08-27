---
title: "Jakarta Mail compatibility"
sidebar:
  label: Jakarta Mail (Java)
---

This assessment considers Mail API compatibility with Jakarta Mail
([Jakarta EE](https://jakarta.ee/specifications/mail/)), formerly JavaMail.
Jakarta Mail provides an extensible MIME message object model and a pluggable
transport SPI (`jakarta.mail.Transport`). It is the foundation for Java email
handling and the underlying model used by [Spring](/compatibility/frameworks/spring/).

| Jakarta Mail concept | Mail API field | Mapping |
| --- | --- | --- |
| `InternetAddress` (`From`, `To`, `Cc`, `Bcc`, `Reply-To`) | `from`, `to`, `cc`, `bcc`, `replyTo` | Convert address and personal name to an `EmailAddress`. |
| `MimeMessage.getSubject()` | `subject` | Direct correspondence. |
| `MimeBodyPart` (`text/plain`, `text/html`) | `text`, `html` | Map text and HTML body parts to their respective fields. |
| `MimeBodyPart` attachments | `attachments` | Base64-encode body content and preserve filename and MIME type. |
| Supplemental headers | `headers` | Preserve headers not mapped to structured fields. |

## Potential transport adapter

A Mail API transport extends `jakarta.mail.Transport` and registers as a
protocol provider (such as `mailapi`). Applications configure the session
property `mail.transport.protocol=mailapi` or call
`session.getTransport("mailapi")`.

The adapter parses the composed `MimeMessage`, constructs an
`OutboundMessageRequest`, and submits it to `POST /v1/messages` over HTTP.
Because Jakarta Mail's `Transport.send()` is synchronous and expects a void
return, the transport treats HTTP `200` as acceptance and raises
`MessagingException` subtypes on HTTP error responses.

## Differences and limits

- A Mail API `200` confirms provider acceptance for asynchronous processing;
  it does not confirm recipient delivery.
- Inline MIME parts with `Content-ID` headers have no structured field in
  Mail API `v1`. The transport requires an explicit policy (such as rejecting
  inline attachments) to prevent broken message rendering.
- `MimeMessage.getSentDate()` has no structured `v1` field; the provider stamps
  the submission time.
- Idempotency requires caller coordination: the transport should accept an
  `Idempotency-Key` via message headers or session properties to make retries
  safe.
- Exception mapping: HTTP `401` should map to
  `AuthenticationFailedException`; `403` should map to `SendFailedException`
  (or another `MessagingException` that represents authorization failure),
  because the credentials were accepted but the submission was not authorized.
  Map `422` to `SendFailedException`. Because the transport itself serializes
  the HTTP request, a `400` indicates an adapter defect rather than a malformed
  caller message and should map to a general `MessagingException`. Unexpected
  provider errors (`500`/`503`) also map to `MessagingException`.
