---
title: Mail API
---

# Mail API

Mail API is a vendor-neutral API specification for sending and receiving email.
It defines an HTTP boundary so applications are not tied directly to a mail
provider.

## API

The current outbound endpoint is:

```text
POST /v1/messages
```

- [OpenAPI specification](openapi.yaml)
- [Versioning policy](versioning.html)

## Compatibility assessments

- [MediaWiki (`IEmailer`)](compatibility/mediawiki.html)
- [WordPress (`wp_mail()`)](compatibility/wordpress.html)
- [Drupal (`MailInterface`)](compatibility/drupal.html)
- [Symfony/Laravel (custom transport)](compatibility/symfony-laravel.html)

### Languages

- [PHP](compatibility/php.html)
- [Go](compatibility/go.html)

## Transport compatibility

- [SMTP](transports/smtp.html)

## Source

The specification and documentation are maintained in the
[mailapi/mailapi](https://github.com/mailapi/mailapi) repository.
