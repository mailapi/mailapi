---
title: Mail API
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
- [Versioning policy](/versioning/)

## Examples

- [Send a message](/examples/send/)
- [Received message](/examples/received/)

## Compatibility assessments

### Cloud mail APIs

- [Amazon SES](/compatibility/clouds/amazon-ses/)
- [Azure Communication Services Email](/compatibility/clouds/azure-email/)
- [Gmail API](/compatibility/clouds/gmail-api/)
- [Resend](/compatibility/clouds/resend/)

### Protocols

- [IMAP](/compatibility/protocols/imap/)
- [JMAP](/compatibility/protocols/jmap/)
- [POP3](/compatibility/protocols/pop/)
- [SMTP](/compatibility/protocols/smtp/)

### Frameworks

- [Drupal (`MailInterface`)](/compatibility/frameworks/drupal/)
- [MediaWiki (`IEmailer`)](/compatibility/frameworks/mediawiki/)
- [Symfony/Laravel (custom transport)](/compatibility/frameworks/symfony-laravel/)
- [WordPress (`wp_mail()`)](/compatibility/frameworks/wordpress/)

### Languages

- [Go](/compatibility/languages/go/)
- [PHP](/compatibility/languages/php/)
- [Python (`email`)](/compatibility/languages/python/)
