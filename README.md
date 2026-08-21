# Mail API

**Mail API is a vendor-neutral API specification for sending and receiving email.**

## Why this exists

Applications such as MediaWiki or WordPress should be able to send and receive email without being tied directly to one provider. This project defines a shared API shape that can be implemented by different providers.

This repository contains the specification only. It does not contain a mail server, provider adapters, SDKs, or application plugins.

## HTTP API

The API defines a single outbound endpoint:

`POST /v1/messages`

The latest released [API reference (Swagger UI)](https://mailapi.github.io/api/)
renders the OpenAPI specification. The source specification is
[`openapi.yaml`](openapi.yaml).

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

`202 Accepted` means the provider has durably accepted responsibility for
asynchronous processing; it does not confirm final recipient delivery. Invalid
requests use standard HTTP error statuses and `application/problem+json`
responses. `429` and `503` may include `Retry-After` to guide a retry.

## Message model

The core message model follows established RFC 5322/MIME concepts where practical, including addresses, body content, attachments, and ordered header fields. The same core model is used for outbound and inbound messages, with inbound metadata (`id`, `receivedAt`) provided by an `InboundMessage` wrapper (see `examples/send.json` and `examples/received.json`).

Structured fields (`from`, `to`, `subject`, and similar) are authoritative for those concepts, while `headers` provides supplemental values including repeatable fields such as `Received`.

## Compatibility assessments

Mail API is designed as a provider-neutral HTTP boundary, not as a drop-in
WordPress plugin or MediaWiki extension. These assessments examine how an
adapter could map a host application's mail abstraction to `POST /v1/messages`,
including the remaining compatibility limits:

### Frameworks

- [MediaWiki (`IEmailer`)](docs/frameworks/mediawiki.md)
- [WordPress (`wp_mail()`)](docs/frameworks/wordpress.md)
- [Drupal (`MailInterface`)](docs/frameworks/drupal.md)
- [Symfony/Laravel (custom transport)](docs/frameworks/symfony-laravel.md)

### Languages

- [PHP](docs/languages/php.md)
- [Go](docs/languages/go.md)
- [Python (`email`)](docs/languages/python.md)

## Versioning

Repository releases use manually created Git tags and GitHub Releases, including
documentation-only releases. `openapi.yaml` `info.version` changes only when
the API contract changes. The current `v1` contract uses the `/v1/` API path. See the
[versioning policy](docs/versioning.md).

## Transports

Mail API defines HTTP submission. See [SMTP transport compatibility](docs/transports/smtp.md)
for the adapter boundary and MIME-to-API mapping when interoperating with SMTP
systems.

## Future transports

The core model is transport-agnostic. Additional transports, such as gRPC, may be defined later without changing the message model.
