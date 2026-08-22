---
title: "MediaWiki Extension"
---

[MailAPI MediaWiki Extension](https://github.com/mailapi/mediawiki-extensions-MailAPI)
routes MediaWiki's outgoing mail through a Mail API service. It uses
MediaWiki's `AlternateUserMailer` hook and maps recipients, text/HTML content,
reply-to, CC/BCC, and supplemental headers to `POST /v1/messages`. The
extension targets MediaWiki 1.43 and later.
