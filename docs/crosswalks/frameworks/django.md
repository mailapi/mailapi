---
title: "Django crosswalk"
sidebar:
  label: Django
---

This crosswalk compares Mail API with Django's `django.core.mail` email
abstraction. Django allows configuring a custom email backend via the
`EMAIL_BACKEND` setting. A Mail API backend subclasses `BaseEmailBackend`,
receives `EmailMessage` and `EmailMultiAlternatives` objects in
`send_messages()`, and submits each message to `POST /v1/messages`.

## References

- [Django sending email guide](https://docs.djangoproject.com/en/stable/topics/email/):
  `EmailMessage`, `EmailMultiAlternatives`, and configuration settings.
- [Django custom email backends](https://docs.djangoproject.com/en/stable/topics/email/#defining-a-custom-email-backend):
  subclassing `BaseEmailBackend` and implementing `send_messages`.
- [Python `email` crosswalk](/crosswalks/languages/python/):
  the underlying Python standard library message model.

## Potential adapter boundary

Configure Django to use the custom backend in `settings.py`:

```python
EMAIL_BACKEND = "mailapi.django.EmailBackend"
MAILAPI_BASE_URL = "https://api.example.com"
MAILAPI_TOKEN = "your-bearer-token"
```

The backend maps Django's `EmailMessage` or `EmailMultiAlternatives` properties
to `OutboundMessageRequest`:

| Django `EmailMessage` property | Mail API field | Mapping |
| --- | --- | --- |
| `from_email` | `from` | Parse with `email.utils.parseaddr()` into an `EmailAddress` object. |
| `to`, `cc`, `bcc` | `to`, `cc`, `bcc` | Parse address lists into `EmailAddress` objects. |
| `reply_to` | `replyTo` | Parse address list into `EmailAddress` objects. |
| `subject` | `subject` | Direct string correspondence. |
| `body` (plain text) | `text` | Maps `body` to `text` when `content_subtype == "plain"`. |
| `alternatives` (`text/html`) | `html` | Extracted from `EmailMultiAlternatives` when an alternative has MIME type `text/html`. |
| `extra_headers` | `headers` | Preserve supplemental headers excluding structured fields. |
| `attachments` | `attachments` | Convert `(filename, content, mimetype)` tuples or `MIMEBase` objects into Base64-encoded attachment records. |

The backend's `send_messages(email_messages)` method iterates over the provided
messages, calls `POST /v1/messages` for each, and returns the number of
successfully accepted messages.

## Differences and limits

- Django's `send_messages()` accepts a list of multiple messages. Because Mail
  API `v1` is a single-message submission endpoint, the backend dispatches each
  message as a separate HTTP request (sequentially or via concurrent HTTP calls)
  and tallies successful responses.
- Django's `fail_silently=True` flag causes the backend to catch HTTP and
  network exceptions and return `0` rather than raising a Python exception.
- Mail API `202` indicates asynchronous acceptance and `200` indicates
  completion within an applied wait. Django's `send_mail()` considers a message
  sent once accepted by the backend, which does not confirm recipient delivery.
- Inline attachments and content IDs (`Content-ID`) created via MIME parts
  require an explicit backend handling policy, as Mail API `v1` models standard
  attachments only.
