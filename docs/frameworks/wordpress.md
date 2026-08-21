# WordPress compatibility

This assessment compares Mail API with WordPress's public `wp_mail()` sending
contract. WordPress exposes a pluggable `wp_mail()` function and the
`pre_wp_mail` filter can preempt sending; either could be an adapter boundary.
An implementation would need one clear boundary and must prevent WordPress's
default mail transport from sending a duplicate message after Mail API accepts
the request.

See the [wp_mail() reference](https://developer.wordpress.org/reference/functions/wp_mail/)
and [`pre_wp_mail` filter reference](https://developer.wordpress.org/reference/hooks/pre_wp_mail/).

## Potential adapter boundary

The adapter converts `wp_mail()` arguments to an `OutboundMessageRequest` and
submits it to `POST /v1/messages`. It then returns success only when Mail API
accepts the message; this is submission success, not recipient delivery.

| `wp_mail()` input | Mail API field | Mapping |
| --- | --- | --- |
| `$to` | `to` | Parse the address string or array into `EmailAddress` values. |
| `$subject` | `subject` | Copy as-is. |
| `$message` | `text` or `html` | Use `html` only when the effective content type is HTML; otherwise use `text`. |
| `From`, `Cc`, `Bcc`, and `Reply-To` in `$headers` | `from`, `cc`, `bcc`, `replyTo` | Parse these structured headers into their corresponding fields. |
| Other `$headers` entries | `headers` | Preserve supplemental and repeated headers in order. |
| `$attachments` filesystem paths | `attachments` | Read each permitted file, Base64-encode its contents, and determine a MIME type. |

## Differences and limits

- Mail API requires `from`, while `wp_mail()` may derive the sender through
  WordPress configuration or filters. The adapter must resolve a sender before
  submitting the request and fail clearly when it cannot.
- WordPress's default body type is plain text. The adapter must use the
  effective `Content-Type` rather than silently treating every body as HTML.
- `$attachments` and `$embeds` are filesystem paths. The adapter must enforce
  local access controls and size limits before reading files. Mail API `v1` has
  no content-ID/inline-embed field, so `$embeds` require an explicit adapter
  policy (for example, reject them) rather than automatic mapping.
- A `true` return from `wp_mail()` and a `202` response from Mail API both mean
  the mail was accepted for processing, not that it reached a recipient.
- Inbound Mail API examples do not provide a WordPress inbound-mail feature or
  callback endpoint. Authentication, retries, and delivery events remain
  deployment-specific.
