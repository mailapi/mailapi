# Laravel integration

This document maps Mail API to Laravel's custom mail transport extension point.
Laravel uses Symfony Mailer and allows applications to register a custom
transport with `Mail::extend()`. A Mail API transport should convert the
Symfony message received by that transport into an `OutboundMessageRequest` and
submit it to `POST /v1/messages`.

See Laravel's [custom transports documentation](https://laravel.com/docs/12.x/mail#custom-transports).

## Adapter boundary

The transport is preferable to intercepting individual `Mailable` classes: it
receives the fully rendered message after Laravel has applied recipients,
headers, text/HTML bodies, and attachments. Configure the transport as a named
mailer in `config/mail.php`, then select it as the application's default or for
individual messages.

| Symfony message data | Mail API field | Mapping |
| --- | --- | --- |
| Sender address | `from` | Convert the address and display name to an `EmailAddress`. |
| To, Cc, Bcc, and Reply-To addresses | `to`, `cc`, `bcc`, `replyTo` | Convert each address to an `EmailAddress`. |
| Subject | `subject` | Copy as-is. |
| Text and HTML bodies | `text`, `html` | Preserve both representations when present. |
| Supplemental headers | `headers` | Preserve headers not mapped to structured fields. |
| Attachments | `attachments` | Read the attachment body, Base64-encode it, and retain filename and MIME type. |

## Differences and limits

- Laravel supports inline embedded attachments with content IDs. Mail API 0.1
  has no content-ID/inline-embed field, so the transport needs an explicit
  policy, such as rejecting embeds, rather than silently emitting broken HTML.
- The transport should map a successful Mail API `202` to Symfony/Laravel send
  success, but must not present it as recipient delivery confirmation.
- Queueing remains Laravel's responsibility: queued jobs invoke the selected
  transport when they run. Mail API does not replace Laravel's queue policy.
- Inbound Mail API examples do not provide a Laravel inbound-mail feature or
  callback endpoint. Authentication, retries, and delivery events remain
  deployment-specific.
