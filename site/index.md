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
| `200` | Provider accepted responsibility for asynchronous processing; this does not confirm final recipient delivery. | Do not retry. |
| `400` | Malformed JSON or invalid request syntax. | Correct the request first. |
| `413` | Request body or attachment content exceeds a provider limit. | Reduce the request first. |
| `415` | Unsupported request media type. | Correct the request first. |
| `409` | `Idempotency-Key` conflicts with a different payload or matching request still in progress. | Use a new key for a different message; retry a matching in-progress request later. |
| `422` | Message fields are semantically invalid. | Correct the message first. |
| `429` | Submission rate limit exceeded. | Retry after `Retry-After` when provided. |
| `500` | Unexpected provider error; the submission outcome may be unknown. | Retry only under a caller policy that accepts duplicate-submission risk. |
| `503` | Provider is temporarily unable to accept the message. | Retry after `Retry-After` when provided. |

Error responses use `application/problem+json`.

To make a submission safe to retry, clients can supply an `Idempotency-Key`
header containing a unique 1–256 character key. For 24 hours, a retry with the
same key and identical payload returns the original successful result instead
of submitting a duplicate message.

## Examples

- [Send a message](examples/send.html)
- [Received message](examples/received.html)

## Compatibility assessments

### Cloud mail APIs

- [Amazon SES](compatibility/clouds/amazon-ses.html)
- [Azure Communication Services Email](compatibility/clouds/azure-email.html)
- [Gmail API](compatibility/clouds/gmail-api.html)
- [Resend](compatibility/clouds/resend.html)

### Protocols

- [JMAP](compatibility/protocols/jmap.html)
- [SMTP](compatibility/protocols/smtp.html)

### Frameworks

- [Drupal (`MailInterface`)](compatibility/frameworks/drupal.html)
- [MediaWiki (`IEmailer`)](compatibility/frameworks/mediawiki.html)
- [Symfony/Laravel (custom transport)](compatibility/frameworks/symfony-laravel.html)
- [WordPress (`wp_mail()`)](compatibility/frameworks/wordpress.html)

### Languages

- [Go](compatibility/languages/go.html)
- [PHP](compatibility/languages/php.html)
- [Python (`email`)](compatibility/languages/python.html)
