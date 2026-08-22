---
title: "Python `email` compatibility"
sidebar:
  label: Python email
---

This assessment considers Mail API compatibility with Python's standard
library [`email`](https://docs.python.org/3/library/email.html) package.
`email` provides an RFC-oriented message and MIME object model; it deliberately
does not send messages. That makes it a strong fit for constructing or parsing
the Mail API message model, while HTTP submission remains a separate concern.

| Python `EmailMessage` concept | Mail API field | Compatibility observation |
| --- | --- | --- |
| Address headers (`From`, `To`, `Cc`, `Bcc`, `Reply-To`) | `from`, `to`, `cc`, `bcc`, `replyTo` | A strong mapping after parsing display names and addresses. |
| `Subject` header | `subject` | Direct correspondence. |
| `set_content()` | `text` | Direct mapping for a plain-text body. |
| `add_alternative()` | `html` | A natural mapping for the HTML member of a multipart alternative message. |
| `add_attachment()` | `attachments` | The attachment bytes, filename, and MIME type can be mapped to the API's Base64 attachment representation. |
| Other message headers | `headers` | Preserve supplemental and repeatable headers, without duplicating structured fields. |

## Limits and transport boundary

- The `email` package is intentionally not a delivery mechanism. A Python
  application needs an HTTP client to submit the resulting JSON to
  `POST /v1/messages`; this does not diminish the message-model compatibility.
- Existing code that passes an `EmailMessage` to
  [`smtplib`](https://docs.python.org/3/library/smtplib.html) still has SMTP
  envelope semantics to account for. In particular, the envelope sender and
  recipients may differ from visible headers. See the
  [SMTP compatibility assessment](../protocols/smtp.md).
- Inline MIME parts referenced by content IDs have no Mail API `v1` equivalent.
  They require a documented transformation or rejection policy.
- A `200` response confirms API submission acceptance only; it does not
  confirm recipient delivery.
