---
title: Implementations
---

These projects implement Mail API at application or provider boundaries. They
are separate repositories with their own release and support policies.

## MediaWiki Extension

[MailAPI MediaWiki Extension](https://github.com/mailapi/mediawiki-extension-MailAPI)
routes MediaWiki's outgoing mail through a Mail API service. It uses
MediaWiki's `AlternateUserMailer` hook and maps recipients, text/HTML content,
reply-to, CC/BCC, and supplemental headers to `POST /v1/messages`. The
extension targets MediaWiki 1.43 and later.

## Resend Mailer

[Resend Mailer](https://github.com/mailapi/resend-mailer) is a Go server that
implements `POST /v1/messages` using the official Resend Go SDK. It supports
Mail API idempotency keys, RFC 9457 problem details, custom headers, and Base64
attachments, allowing a Mail API client to deliver through Resend.
