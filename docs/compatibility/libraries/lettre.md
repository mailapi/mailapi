---
title: "Rust `lettre` compatibility"
sidebar:
  label: lettre (Rust)
---

This assessment considers Mail API compatibility with the Rust
[`lettre`](https://docs.rs/lettre/latest/lettre/) crate. Lettre provides a
typed message builder with address, multipart body, attachment, and SMTP
transport support. It is a strong source model for a Mail API adapter, but its
built-in transports send SMTP messages rather than Mail API HTTP requests.

| `lettre` concept | Mail API field | Compatibility observation |
| --- | --- | --- |
| `Message::builder()` addresses | `from`, `to`, `cc`, `bcc`, `replyTo` | Direct correspondence for structured mailbox headers. |
| `subject()` | `subject` | Direct correspondence. |
| `SinglePart` and `MultiPart::alternative()` | `text`, `html` | Plain-text and HTML alternatives can be mapped before MIME encoding. |
| `Attachment` | `attachments` | Filename, content type, and bytes can be converted to Mail API's Base64 content. |
| Message headers | `headers` | Preserve application-defined headers after excluding fields represented by structured Mail API properties. |

## Submission adapter

Use an application adapter to turn the structured message inputs into a
`POST /v1/messages` JSON request. Do this before calling
[`Message::formatted()`](https://docs.rs/lettre/latest/lettre/struct.Message.html),
because formatted MIME output combines headers and body parts into an opaque
byte stream that requires parsing to recover Mail API fields.

Lettre's SMTP transports remain useful when SMTP is the intended delivery
mechanism. For adapting existing SMTP submission code, see the
[SMTP compatibility assessment](/compatibility/protocols/smtp/).

## Limits and response handling

- A successful Mail API `200` confirms provider acceptance for asynchronous
  processing; it does not confirm final recipient delivery.
- Inline attachments with content IDs need an application policy because Mail
  API `v1` has no equivalent structured field.
- Preserve retry safety by mapping a caller-generated idempotency key to the
  `Idempotency-Key` request header; Lettre does not supply an equivalent
  transport-level mechanism for HTTP submission.
