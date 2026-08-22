---
title: "PHP compatibility"
---

# PHP compatibility

This assessment considers Mail API compatibility with PHP applications in
general. PHP can readily submit the API's JSON over HTTP, but the quality of
mapping from an existing mail call depends on the mail abstraction in use.

PHP's built-in [`mail()`](https://www.php.net/manual/en/function.mail.php)
accepts recipient, subject, message, supplemental headers, and a boolean-style
send result. Those concepts provide a basic correspondence with Mail API, but
they do not expose a complete structured message model.

| PHP `mail()` input | Mail API field | Compatibility observation |
| --- | --- | --- |
| `$to` | `to` | Address parsing is required. |
| `$subject` | `subject` | Direct correspondence. |
| `$message` | `text` or `html` | The content type must be inferred from headers or application policy. |
| `$additional_headers` | `from`, `cc`, `bcc`, `replyTo`, `headers` | Structured address headers must be parsed before supplemental headers are preserved. |

## Limits and stronger abstractions

- `mail()` has no standard attachment argument and provides a single opaque
  message body. MIME attachments and alternate text/HTML bodies need
  application-specific parsing or construction before they can map to Mail API.
- PHP's boolean send result and Mail API's `200` both indicate submission
  acceptance, not final delivery to a recipient.
- PHP applications using Symfony Mailer have a substantially stronger match:
  its composed message and custom transport boundary retain structured
  recipients, both body types, and attachments. See the
  [Symfony/Laravel compatibility assessment](symfony-laravel.md).
- Inline attachments with content IDs remain a Mail API `v1` gap regardless of
  the PHP mail library.

