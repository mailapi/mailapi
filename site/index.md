---
title: Mail API
---

# Mail API

Mail API is a vendor-neutral API specification for sending and receiving email.
It defines an HTTP boundary so applications are not tied directly to a mail
provider.

Repository release: `{{ site.repository_version }}` ·
[Source: mailapi/mailapi](https://github.com/mailapi/mailapi)

## API

The current outbound endpoint is:

```text
POST /v1/messages
```

- [API reference (Swagger UI)](api/)
- [OpenAPI source (`openapi.yaml`)](openapi.yaml)
- [Versioning policy](versioning.html)

## Submission responses

| Status | Meaning | Retry guidance |
| --- | --- | --- |
| `202` | Provider durably accepted responsibility for asynchronous processing; this does not confirm final recipient delivery. | Do not retry. |
| `400` | Malformed JSON or invalid request syntax. | Correct the request first. |
| `413` | Request body or attachment content exceeds a provider limit. | Reduce the request first. |
| `415` | Unsupported request media type. | Correct the request first. |
| `422` | Message fields are semantically invalid. | Correct the message first. |
| `429` | Submission rate limit exceeded. | Retry after `Retry-After` when provided. |
| `500` | Unexpected provider error. | Retry only under the caller's failure policy. |
| `503` | Provider is temporarily unable to accept the message. | Retry after `Retry-After` when provided. |

Error responses use `application/problem+json`.

## Compatibility assessments

### Frameworks

- [MediaWiki (`IEmailer`)](frameworks/mediawiki.html)
- [WordPress (`wp_mail()`)](frameworks/wordpress.html)
- [Drupal (`MailInterface`)](frameworks/drupal.html)
- [Symfony/Laravel (custom transport)](frameworks/symfony-laravel.html)

### Languages

- [PHP](languages/php.html)
- [Go](languages/go.html)
- [Python (`email`)](languages/python.html)

## Transport compatibility

- [SMTP](transports/smtp.html)
