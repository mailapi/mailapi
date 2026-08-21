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

## Integration guides

- [MediaWiki (`IEmailer`)](integrations/mediawiki.html)
- [WordPress (`wp_mail()`)](integrations/wordpress.html)
- [Drupal (`MailInterface`)](integrations/drupal.html)
- [Laravel (custom transport)](integrations/laravel.html)

## Source

The specification and documentation are maintained in the
[mailapi/mailapi](https://github.com/mailapi/mailapi) repository.
