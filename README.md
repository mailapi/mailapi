# Mail API

**Mail API is a vendor-neutral API specification for sending and receiving email.**

## Why this exists

Applications such as MediaWiki or WordPress should be able to send and receive email without being tied directly to one provider. This project defines a shared API shape that can be implemented by different providers.

This repository contains the specification only. It does not contain a mail server, provider adapters, SDKs, or application plugins.

## HTTP API

The API defines a single outbound endpoint:

`POST /v1/messages`

The latest released [API reference](https://mailapi.github.io/api/)
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
`https://api.example.com/problems/idempotency-key-in-progress`. See [the
complete HTTP request example](https://mailapi.github.io/examples/send/).

## Message model

The core message model follows established RFC 5322/MIME concepts where practical, including addresses, body content, attachments, and ordered header fields. The same core model is used for outbound and inbound messages, with inbound metadata (`id`, `receivedAt`) provided by an `InboundMessage` wrapper. See the [outbound](https://mailapi.github.io/examples/send/) and [inbound](https://mailapi.github.io/examples/received/) examples.

Structured fields (`from`, `to`, `subject`, and similar) are authoritative for those concepts, while `headers` provides supplemental values including repeatable fields such as `Received`.

## Implementations

- [MailAPI MediaWiki Extension](https://github.com/mailapi/mediawiki-extensions-MailAPI)
  routes MediaWiki mail through a Mail API service.
- [Resend Mailer](https://github.com/mailapi/resend-mailer) implements the Mail
  API message-sending endpoint using Resend.

## Compatibility assessments

Mail API is designed as a provider-neutral HTTP boundary, not as a drop-in
WordPress plugin or MediaWiki extension. These assessments examine how an
adapter could map a host application's mail abstraction to `POST /v1/messages`,
including the remaining compatibility limits:

### Frameworks

- [MediaWiki (`IEmailer`)](https://mailapi.github.io/compatibility/frameworks/mediawiki/)
- [WordPress (`wp_mail()`)](https://mailapi.github.io/compatibility/frameworks/wordpress/)
- [Drupal (`MailInterface`)](https://mailapi.github.io/compatibility/frameworks/drupal/)
- [Symfony/Laravel (custom transport)](https://mailapi.github.io/compatibility/frameworks/symfony-laravel/)

### Languages

- [PHP](https://mailapi.github.io/compatibility/languages/php/)
- [Rust (`lettre`)](https://mailapi.github.io/compatibility/languages/rust/)
- [Python (`email`)](https://mailapi.github.io/compatibility/languages/python/)

### Cloud mail APIs

- [Amazon SES](https://mailapi.github.io/compatibility/clouds/amazon-ses/)
- [Gmail API](https://mailapi.github.io/compatibility/clouds/gmail-api/)
- [Azure Communication Services Email](https://mailapi.github.io/compatibility/clouds/azure-email/)
- [Resend](https://mailapi.github.io/compatibility/clouds/resend/)

### Protocols

- [IMAP](https://mailapi.github.io/compatibility/protocols/imap/)
- [JMAP](https://mailapi.github.io/compatibility/protocols/jmap/)
- [POP3](https://mailapi.github.io/compatibility/protocols/pop/)

## Versioning

Repository releases use manually created Git tags and GitHub Releases, including
documentation-only releases. `openapi.yaml` `info.version` changes only when
the API contract changes. The current `v1` contract uses the `/v1/` API path. See the
[versioning policy](https://mailapi.github.io/versioning/).

## Protocols

Mail API defines HTTP submission. See [SMTP compatibility](https://mailapi.github.io/compatibility/protocols/smtp/)
for the adapter boundary and MIME-to-API mapping when interoperating with SMTP
systems. [IMAP compatibility](https://mailapi.github.io/compatibility/protocols/imap/) explains the
separate mailbox-access and inbound-retrieval boundary; [POP3
compatibility](https://mailapi.github.io/compatibility/protocols/pop/) covers simple maildrop
retrieval.

## Future transports

The core model is transport-agnostic. Additional transports, such as gRPC, may be defined later without changing the message model.
