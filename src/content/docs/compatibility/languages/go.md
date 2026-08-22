---
title: "Go compatibility"
---

This assessment considers Mail API compatibility with Go applications. The API
is a strong fit at the HTTP/JSON boundary: Go's standard
[`net/http`](https://pkg.go.dev/net/http) package provides HTTP client support,
and the request and response schemas map naturally to Go structs.

| Mail API concept | Go compatibility observation |
| --- | --- |
| HTTP submission | `net/http.Client` can submit JSON requests and inspect the `200` response. |
| Addresses, headers, and attachments | These can be represented directly with typed structs, slices, and Base64 strings. |
| Request cancellation and timeouts | The HTTP client and request context provide the required controls. |
| Concurrent use | A reused `http.Client` is safe for concurrent use. |

## Existing SMTP mail code

Compatibility is weaker when adapting existing SMTP-oriented Go code. The
standard [`net/smtp`](https://pkg.go.dev/net/smtp) package is frozen, and it
operates on SMTP envelope commands plus a raw message body rather than a
complete structured MIME message model. `net/mail` can parse addresses and
messages, but an SMTP-to-Mail-API adapter still needs explicit MIME parsing and
policies for headers, body alternatives, and attachments.

- Map a structured application message directly to Mail API when possible.
- For raw SMTP/MIME input, apply the rules in the
  [SMTP compatibility assessment](../protocols/smtp.md).
- Do not treat a `200` response as recipient delivery confirmation.
- Inline attachments with content IDs require an explicit policy because Mail
  API 0.1 has no equivalent field.
