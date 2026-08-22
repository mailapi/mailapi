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
| `500` | Unexpected provider error; the submission outcome may be unknown. | Without an `Idempotency-Key`, retry only under a caller policy that accepts duplicate-submission risk. |
| `503` | Provider is temporarily unable to accept the message. | Retry after `Retry-After` when provided. |

Error responses use `application/problem+json`.

To make a submission safe to retry, clients can supply an `Idempotency-Key`
header containing a unique 1–256 character key. For 24 hours, a retry with the
same key and byte-for-byte identical UTF-8 request body returns the original
successful result instead of submitting a duplicate message. JSON whitespace
and object-member ordering are significant. Reusing a key with a different body
returns problem type `https://api.example.com/problems/idempotency-key-reused`;
retrying while the matching submission is in progress returns
`https://api.example.com/problems/idempotency-key-in-progress`.

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
