# Drupal compatibility

This assessment compares Mail API with Drupal's pluggable
`Drupal\Core\Mail\MailInterface` mail back-end. A potential Mail API module
would receive the composed Drupal message in `mail(array $message)` and submit
an `OutboundMessageRequest` to `POST /v1/messages`.

See the [MailInterface reference](https://api.drupal.org/api/drupal/core%21lib%21Drupal%21Core%21Mail%21MailInterface.php/function/MailInterface%3A%3Amail/11.x).

## Potential adapter boundary

`MailManagerInterface` composes messages and selects a mail plug-in. The Mail
API adapter belongs at the selected `MailInterface` implementation, after
Drupal has constructed the message. This keeps module-specific templates and
`hook_mail_alter()` changes inside Drupal while replacing only delivery.

| Drupal message field | Mail API field | Mapping |
| --- | --- | --- |
| `to` | `to` | Parse the address string into `EmailAddress` values. |
| `subject` | `subject` | Copy the composed subject. |
| `body`, plus `plain` when present | `text`, `html` | Map `body` according to the effective content type; when it is HTML, preserve `plain` as the alternate `text` body. |
| `headers['From']` | `from` | Parse the sender into an `EmailAddress`; reject the submission if it is absent. |
| `headers['Cc']`, `headers['Bcc']`, `headers['Reply-To']` | `cc`, `bcc`, `replyTo` | Parse these structured headers into their corresponding fields. |
| Other `headers` entries | `headers` | Preserve supplemental headers. |

## Differences and limits

- Drupal's standard message array has no portable attachment field. A generic
  Mail API plug-in must not infer `attachments`; modules that need attachments
  require an explicit extension contract.
- Drupal may format an HTML body and an alternate plain-text body. An adapter
  should preserve both when they are available instead of silently discarding
  one representation.
- `MailInterface::mail()` returns whether Drupal accepted the message for
  delivery. A Mail API `200` likewise means provider acceptance, not recipient
  delivery.
- Inbound Mail API examples do not provide a Drupal inbound-mail feature or
  callback endpoint. Authentication, retries, delivery events, and attachment
  limits remain deployment-specific.

