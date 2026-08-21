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

## Differences and limits

- `IEmailer::send()` has no attachment parameter. An adapter cannot infer Mail
  API `attachments` at this boundary; it should neither add them nor claim that
  they are supported.
- The return value is a MediaWiki `StatusValue`; a Mail API `202` only confirms
  provider acceptance. The adapter must translate submission failures to an
  appropriate failed status and must not report recipient delivery as complete.
- Inbound Mail API examples are data representations only. They do not add a
  MediaWiki inbound-mail feature or a callback endpoint.
- Authentication, retries, delivery events, and attachment-size limits are not
  specified by Mail API `v1` and remain deployment-specific.
