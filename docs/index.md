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

## Crosswalks

### Email provider APIs

- [Amazon SES](/crosswalks/providers/amazon-ses/)
- [Azure Communication Services Email](/crosswalks/providers/azure-email/)
- [Gmail API](/crosswalks/providers/gmail-api/)
- [Mailgun](/crosswalks/providers/mailgun/)
- [Microsoft Graph](/crosswalks/providers/microsoft-graph/)
- [Resend](/crosswalks/providers/resend/)
- [SendGrid](/crosswalks/providers/sendgrid/)

### Standards

- [IMAP](/crosswalks/standards/imap/)
- [JMAP](/crosswalks/standards/jmap/)
- [MIME](/crosswalks/standards/mime/)
- [POP3](/crosswalks/standards/pop3/)
- [SMTP](/crosswalks/standards/smtp/)

The caller-side crosswalks are grouped by the layer an adapter attaches to,
from the language upward.

### Languages

Mail facilities that ship with the language, with no added dependency.

- [PHP (`mail()`)](/crosswalks/languages/php/)
- [Python (`email`)](/crosswalks/languages/python/)

### Libraries

Framework-agnostic libraries added as a dependency to compose or send mail.

- [Jakarta Mail (Java)](/crosswalks/libraries/jakarta-mail/)
- [lettre (Rust)](/crosswalks/libraries/lettre/)
- [Nodemailer (Node.js)](/crosswalks/libraries/nodemailer/)
- [Symfony Mailer (PHP)](/crosswalks/libraries/symfony-mailer/)

### Frameworks

Application frameworks that own mail configuration and expose a swappable
transport or sender.

- [Django](/crosswalks/frameworks/django/)
- [Laravel (`Mail::extend()`)](/crosswalks/frameworks/laravel/)
- [Spring (`JavaMailSender`)](/crosswalks/frameworks/spring/)

### Applications

Deployed products with a mail hook an extension can replace.

- [Drupal (`MailInterface`)](/crosswalks/applications/drupal/)
- [MediaWiki (`IEmailer`)](/crosswalks/applications/mediawiki/)
- [WordPress (`wp_mail()`)](/crosswalks/applications/wordpress/)
