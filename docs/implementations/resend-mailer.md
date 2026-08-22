---
title: "Resend Mailer"
---

[Resend Mailer](https://github.com/mailapi/resend-mailer) is a Go server that
implements `POST /v1/messages` using the official Resend Go SDK. It supports
Mail API idempotency keys, RFC 9457 problem details, custom headers, and Base64
attachments, allowing a Mail API client to deliver through Resend.
