# Mail API

**Mail API is a vendor-neutral API specification for sending and receiving
email.**

## Why this exists

Applications such as MediaWiki or WordPress should be able to send and receive
email without being tied directly to one provider. This project defines a
shared API shape that can be implemented by different providers.

This repository contains the specification only. It does not contain a mail
server, provider adapters, SDKs, or application plugins.

## HTTP API

The API defines a single outbound endpoint:

```text
POST /v1/messages
```

Example request:

```http
POST /v1/messages HTTP/1.1
Content-Type: application/json
Authorization: Bearer <token>

{
  "from": { "email": "noreply@example.org", "name": "Example App" },
  "to": [{ "email": "user@example.net", "name": "Example User" }],
  "subject": "Welcome",
  "text": "Hello from Mail API"
}
```

The provider accepts the message for asynchronous processing and returns a Mail
API message identifier. This does not confirm final recipient delivery.

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": "msg_01HZXKJ42P6X0Q7J9ZMY1P4R8B"
}
```

Errors use `application/problem+json` with a `type` from the specification's
[problem type registry](https://mailapi.github.io/problems/). Retries can be
made safe with an `Idempotency-Key` header.

## Documentation

The documentation site is the single source of truth for the contract; this
README is only an entry point.

- [Documentation home](https://mailapi.github.io/) — submission response table,
  authentication, and idempotency rules
- [API reference](https://mailapi.github.io/api/) — rendered from
  [`openapi.yaml`](openapi.yaml)
- [Problem types](https://mailapi.github.io/problems/) — the error identifier
  registry
- [Versioning policy](https://mailapi.github.io/concepts/versioning/)
- [Design rationale](https://mailapi.github.io/concepts/rationale/) — why the contract
  makes its non-obvious choices, starting with `200` over `202`
- Examples: [send](https://mailapi.github.io/examples/send/) and
  [received](https://mailapi.github.io/examples/received/)

## Message model

The core message model follows established RFC 5322/MIME concepts where
practical, including addresses, body content, attachments, and ordered header
fields. The same core model is used for outbound and inbound messages, with
inbound metadata (`id`, `receivedAt`) provided by an `InboundMessage` wrapper.

Structured fields (`from`, `to`, `subject`, and similar) are authoritative for
those concepts, while `headers` provides supplemental values including
repeatable fields such as `Received`. An `extensions` object carries
provider-specific members so the rest of the model can stay strictly
validated.

## Implementations

- [MailAPI MediaWiki Extension](https://github.com/mailapi/mediawiki-extensions-MailAPI)
  routes MediaWiki mail through a Mail API service.
- [Resend Mailer](https://github.com/mailapi/resend-mailer) implements the Mail
  API message-sending endpoint using Resend.

## Compatibility assessments

Mail API is designed as a provider-neutral HTTP boundary, not as a drop-in
WordPress plugin or MediaWiki extension. These assessments examine how an
adapter could map a host application's mail abstraction to `POST /v1/messages`,
including the remaining compatibility limits.

Clouds:

- [Amazon SES](https://mailapi.github.io/compatibility/clouds/amazon-ses/)
- [Azure Communication Services Email](https://mailapi.github.io/compatibility/clouds/azure-email/)
- [Gmail API](https://mailapi.github.io/compatibility/clouds/gmail-api/)
- [Resend](https://mailapi.github.io/compatibility/clouds/resend/)
- [SendGrid](https://mailapi.github.io/compatibility/clouds/sendgrid/)

Protocols:

- [IMAP](https://mailapi.github.io/compatibility/protocols/imap/)
- [JMAP](https://mailapi.github.io/compatibility/protocols/jmap/)
- [POP3](https://mailapi.github.io/compatibility/protocols/pop/)
- [SMTP](https://mailapi.github.io/compatibility/protocols/smtp/)

The caller-side assessments are grouped by the layer an adapter attaches to,
from the language upward.

Languages, meaning mail facilities that ship with the language:

- [PHP (`mail()`)](https://mailapi.github.io/compatibility/languages/php/)
- [Python (`email`)](https://mailapi.github.io/compatibility/languages/python/)

Libraries, meaning framework-agnostic dependencies that compose or send mail:

- [Jakarta Mail (Java)](https://mailapi.github.io/compatibility/libraries/jakarta-mail/)
- [lettre (Rust)](https://mailapi.github.io/compatibility/libraries/lettre/)
- [Symfony Mailer (PHP)](https://mailapi.github.io/compatibility/libraries/symfony-mailer/)

Frameworks, meaning application frameworks with a swappable transport or
sender:

- [Laravel (`Mail::extend()`)](https://mailapi.github.io/compatibility/frameworks/laravel/)
- [Spring (`JavaMailSender`)](https://mailapi.github.io/compatibility/frameworks/spring/)

Applications, meaning deployed products with a replaceable mail hook:

- [Drupal (`MailInterface`)](https://mailapi.github.io/compatibility/applications/drupal/)
- [MediaWiki (`IEmailer`)](https://mailapi.github.io/compatibility/applications/mediawiki/)
- [WordPress (`wp_mail()`)](https://mailapi.github.io/compatibility/applications/wordpress/)

Mail API defines HTTP submission only.
[SMTP compatibility](https://mailapi.github.io/compatibility/protocols/smtp/)
covers the adapter boundary and MIME-to-API mapping;
[IMAP](https://mailapi.github.io/compatibility/protocols/imap/) and
[POP3](https://mailapi.github.io/compatibility/protocols/pop/) cover the
separate mailbox-access and inbound-retrieval boundary.

## Future transports

The core model is transport-agnostic. Additional transports, such as gRPC, may
be defined later without changing the message model.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the local checks that CI runs and
the release process.

## License

[Apache-2.0](LICENSE)
