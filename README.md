# Mail API spec

**Mail API is a vendor-neutral API specification for sending and receiving email.**

## Why this exists

Applications such as MediaWiki or WordPress should be able to send and receive email without being tied directly to one provider. This project defines a shared API shape that can be implemented by different providers.

This repository contains the specification only. It does not contain a mail server, provider adapters, SDKs, or application plugins.

## MVP HTTP API

The initial MVP defines a single outbound endpoint:

`POST /v1/messages`

Example request body:

```json
{
  "from": { "email": "noreply@example.org", "name": "Example App" },
  "to": [{ "email": "user@example.net", "name": "Example User" }],
  "subject": "Welcome",
  "text": "Hello from Mail API"
}
```

A successful response returns a Mail API message identifier:

```json
{
  "id": "msg_01HZXKJ42P6X0Q7J9ZMY1P4R8B"
}
```

## Message model

The core message model follows established RFC 5322/MIME concepts where practical, including addresses, body content, attachments, and ordered header fields. The same core model is used for outbound and inbound messages, with inbound metadata (`id`, `receivedAt`) provided by an `InboundMessage` wrapper (see `examples/send.json` and `examples/received.json`).

Structured fields (`from`, `to`, `subject`, and similar) are authoritative for those concepts, while `headers` provides supplemental values including repeatable fields such as `Received`.

## CMS integration compatibility

Mail API is designed as a provider-neutral HTTP boundary, not as a drop-in
WordPress plugin or MediaWiki extension. Integrations need an adapter between
the host application's mail abstraction and `POST /v1/messages`. See the
platform-specific guides for field mappings, adapter responsibilities, and the
current compatibility limits:

- [MediaWiki (`IEmailer`)](docs/integrations/mediawiki.md)
- [WordPress (`wp_mail()`)](docs/integrations/wordpress.md)
- [Drupal (`MailInterface`)](docs/integrations/drupal.md)
- [Symfony/Laravel (custom transport)](docs/integrations/symfony-laravel.md)

## Versioning

Repository releases from `v0.0.0` through `v1.x.x` use the `/v1/` API path;
`v2.x.x` releases use `/v2/`. The OpenAPI `info.version` and GitHub tags identify
the repository release. See the [versioning policy](docs/versioning.md).

## Transports

Mail API defines HTTP submission. See [SMTP transport compatibility](docs/transports/smtp.md)
for the adapter boundary and MIME-to-API mapping when interoperating with SMTP
systems.

## Future transports

The core model is transport-agnostic. Additional transports, such as gRPC, may be defined later without changing the message model.
