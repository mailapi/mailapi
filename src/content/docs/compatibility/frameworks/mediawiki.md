---
title: "MediaWiki compatibility"
---

# MediaWiki compatibility

This assessment compares Mail API with MediaWiki's
`MediaWiki\\Mail\\IEmailer` interface. `IEmailer::send()` is the relevant
outgoing-mail abstraction; it accepts recipients, a sender, subject, text and
optional HTML bodies, and an options array. It is marked internal by MediaWiki,
so an implementation would need to isolate and test this dependency for every
supported MediaWiki version.

See the [IEmailer interface reference](https://doc.wikimedia.org/mediawiki-core/1.39.17/php/interfaceMediaWiki_1_1Mail_1_1IEmailer.html).

## Potential adapter boundary

An adapter receives the arguments to `IEmailer::send()`, constructs an
`OutboundMessageRequest`, and submits it to `POST /v1/messages`. Mail API is
not a built-in MediaWiki mail transport; wiring the adapter into MediaWiki is
the responsibility of an extension or deployment integration.

| `IEmailer::send()` input | Mail API field | Mapping |
| --- | --- | --- |
| `$to` (`MailAddress` or array) | `to` | Convert every address to an `EmailAddress`. |
| `$from` (`MailAddress`) | `from` | Convert the sender to an `EmailAddress`. |
| `$subject` | `subject` | Copy as-is. |
| `$bodyText` | `text` | Copy as-is. |
| `$bodyHtml` | `html` | Include when it is not `null`. |
| `$options['replyTo']` | `replyTo` | Convert to an `EmailAddress` when present. |
| `$options['headers']` | `headers` | Preserve supplemental headers, including repeated names, in order. |
| `$options['contentType']` | `headers` | Preserve as a `Content-Type` header when it is explicitly supplied. |

## Submission semantics

`IEmailer::send()` is a synchronous, single-submission call that returns a
`StatusValue`. A Mail API `200` maps to successful provider acceptance, not
final recipient delivery.

If the HTTP request times out, the adapter cannot determine whether Mail API
accepted the message before the response was lost. A client-supplied
`Idempotency-Key` protects a retry with the same payload for 24 hours; without
one, retrying a timed-out call can create a duplicate message. This is
comparable to an SMTP submission whose final acceptance response is lost;
timeout and retry handling remain an adapter or deployment policy.

The defined HTTP responses let an adapter distinguish non-retryable request
errors (`400`, `413`, `415`, and `422`), idempotency conflicts (`409`), and
retryable rate-limit or temporary provider responses (`429` and `503`). A
matching submission that is still in progress may be retried later; a key used
with a different payload requires a new key or payload. Other `5xx` responses
can leave the submission outcome unknown, so retries require an adapter policy
that accepts duplicate-submission risk. A failed request is translated to a
failed `StatusValue`.

## Differences and limits

- `IEmailer::send()` has no attachment parameter. An adapter cannot infer Mail
  API `attachments` at this boundary; it should neither add them nor claim that
  they are supported.
- Inbound Mail API examples are data representations only. They do not add a
  MediaWiki inbound-mail feature or a callback endpoint.
- Authentication, delivery events, submission-status lookup, and attachment-size
  limits are not specified by Mail API `v1` and remain
  deployment-specific.

