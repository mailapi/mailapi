---
title: "Symfony Mailer crosswalk"
sidebar:
  label: Symfony Mailer (PHP)
---

This crosswalk uses Symfony Mailer's custom transport as the Mail API
boundary. Symfony Mailer is a standalone component: it is usable
without the Symfony framework, and other PHP frameworks delegate to it. A
potential transport would convert the fully composed Symfony message into an
`OutboundMessageRequest` and submit it to `POST /v1/messages`.

See Symfony's [custom transport documentation](https://symfony.com/doc/current/mailer.html#custom-transport-factories).

For the framework-level registration hook, see the
[Laravel crosswalk](/crosswalks/frameworks/laravel/).

## Potential Symfony Mailer transport

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

The transport should treat Mail API `200` and `202` as send success, consistent
with Symfony's definition of success as acceptance by a transport. It can send
`Prefer: wait=N` when bounded synchronous waiting is useful, but must not
present either response as recipient delivery confirmation.

## Differences and limits

- Symfony Mailer supports inline embedded attachments with content IDs. Mail
  API `v1` has no content-ID/inline-embed field, so the transport needs an
  explicit policy, such as rejecting embeds, rather than silently emitting
  broken HTML.
- Inbound Mail API examples do not provide a Symfony Mailer inbound-mail
  feature or callback endpoint.
- Credential issuance and rotation, retries, delivery events, and
  attachment-size limits remain deployment-specific. Mail API defines the `401`
  and `403` responses the transport must surface, not how a token is obtained.
