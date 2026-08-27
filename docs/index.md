---
title: Mail API
head:
  - tag: title
    content: Mail API
---

Mail API is a vendor-neutral API specification for sending and receiving email.
It defines an HTTP boundary so applications are not tied directly to a mail
provider.

## API

The current outbound endpoint is:

```text
POST /v1/messages
```

- [API reference](/api/)
- [OpenAPI source (`openapi.yaml`)](https://github.com/mailapi/mailapi/blob/main/openapi.yaml)
- [Problem types](/problems/)

## Concepts

- [Scope and capabilities](/concepts/scope/) — what `v1` supports, deliberately
  omits, or reserves for a future capability.
- [Authentication](/concepts/authentication/) — the bearer token a request carries.
- [Submission responses](/concepts/responses/) — every status code and its
  retry guidance.
- [Idempotency](/concepts/idempotency/) — how `Idempotency-Key` makes a retry safe.
- [Versioning policy](/concepts/versioning/) — what may change without a new
  major version.
- [Design rationale](/concepts/rationale/) — why the contract is shaped this way.

## Examples

- [Send a message](/examples/send/)
- [Received message](/examples/received/)

## Implementations

- [MediaWiki Extension](/implementations/mediawiki-extension/)
- [Resend Mailer](/implementations/resend-mailer/)

## Compatibility assessments

### Cloud mail APIs

- [Amazon SES](/compatibility/clouds/amazon-ses/)
- [Azure Communication Services Email](/compatibility/clouds/azure-email/)
- [Gmail API](/compatibility/clouds/gmail-api/)
- [Resend](/compatibility/clouds/resend/)
- [SendGrid](/compatibility/clouds/sendgrid/)

### Protocols

- [IMAP](/compatibility/protocols/imap/)
- [JMAP](/compatibility/protocols/jmap/)
- [POP3](/compatibility/protocols/pop/)
- [SMTP](/compatibility/protocols/smtp/)

The caller-side assessments are grouped by the layer an adapter attaches to,
from the language upward.

### Languages

Mail facilities that ship with the language, with no added dependency.

- [PHP (`mail()`)](/compatibility/languages/php/)
- [Python (`email`)](/compatibility/languages/python/)

### Libraries

Framework-agnostic libraries added as a dependency to compose or send mail.

- [Jakarta Mail (Java)](/compatibility/libraries/jakarta-mail/)
- [lettre (Rust)](/compatibility/libraries/lettre/)
- [Symfony Mailer (PHP)](/compatibility/libraries/symfony-mailer/)

### Frameworks

Application frameworks that own mail configuration and expose a swappable
transport or sender.

- [Laravel (`Mail::extend()`)](/compatibility/frameworks/laravel/)
- [Spring (`JavaMailSender`)](/compatibility/frameworks/spring/)

### Applications

Deployed products with a mail hook an extension can replace.

- [Drupal (`MailInterface`)](/compatibility/applications/drupal/)
- [MediaWiki (`IEmailer`)](/compatibility/applications/mediawiki/)
- [WordPress (`wp_mail()`)](/compatibility/applications/wordpress/)
