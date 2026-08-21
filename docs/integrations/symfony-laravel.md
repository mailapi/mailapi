# Symfony/Laravel integration

This guide uses Symfony Mailer's custom transport as the common Mail API
integration boundary. A transport converts the fully composed Symfony message
into an `OutboundMessageRequest` and submits it to `POST /v1/messages`.

See Symfony's [custom transport documentation](https://symfony.com/doc/current/mailer.html#custom-transport-factories).

## Symfony Mailer transport

Implement a Mail API transport and transport factory, then register the factory
with the `mailer.transport_factory` service tag. This is preferable to
intercepting individual messages: the transport receives the rendered message
after Symfony has applied recipients, headers, text/HTML bodies, and
attachments.

| Symfony message data | Mail API field | Mapping |
| --- | --- | --- |
| Sender address | `from` | Convert the address and display name to an `EmailAddress`. |
| To, Cc, Bcc, and Reply-To addresses | `to`, `cc`, `bcc`, `replyTo` | Convert each address to an `EmailAddress`. |
| Subject | `subject` | Copy as-is. |
| Text and HTML bodies | `text`, `html` | Preserve both representations when present. |
| Supplemental headers | `headers` | Preserve headers not mapped to structured fields. |
| Attachments | `attachments` | Read the attachment body, Base64-encode it, and retain filename and MIME type. |

The transport should treat a Mail API `202` as send success, consistent with
Symfony's definition of success as acceptance by a transport. It must not
present this as recipient delivery confirmation.

## Laravel

Laravel uses Symfony Mailer. Register the same transport through
`Mail::extend()`, configure it as a named mailer in `config/mail.php`, and
select it as the default mailer or for individual messages. Laravel queueing
remains unchanged: queued jobs invoke the selected transport when they run.

See Laravel's [custom transports documentation](https://laravel.com/docs/12.x/mail#custom-transports).

## Differences and limits

- Symfony and Laravel support inline embedded attachments with content IDs. Mail
  API 0.1 has no content-ID/inline-embed field, so the transport needs an
  explicit policy, such as rejecting embeds, rather than silently emitting
  broken HTML.
- Inbound Mail API examples do not provide a Symfony or Laravel inbound-mail
  feature or callback endpoint.
- Authentication, retries, delivery events, and attachment-size limits remain
  deployment-specific.
