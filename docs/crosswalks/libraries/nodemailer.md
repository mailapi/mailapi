---
title: "Node.js Nodemailer crosswalk"
sidebar:
  label: Nodemailer (Node.js)
---

This crosswalk compares Mail API with Node.js's de-facto standard
[`nodemailer`](https://nodemailer.com/) library. Nodemailer provides a flexible
message builder and a pluggable transport interface (`nodemailer.createTransport`).
A custom Mail API transport receives composed Nodemailer mail objects, serializes
an `OutboundMessageRequest`, and submits it to `POST /v1/messages`.

## References

- [Nodemailer message configuration](https://nodemailer.com/message/):
  address fields, dual plain/HTML bodies, attachments, and custom headers.
- [Nodemailer custom transport plugin architecture](https://nodemailer.com/plugins/create/):
  implementing the `send(mail, callback)` transport contract.
- [Nodemailer attachments guide](https://nodemailer.com/message/attachments/):
  string, buffer, stream, and data-URL attachment representations.

## Potential transport adapter

A Mail API transport implements Nodemailer's `Transport` interface by defining a
`send(mail, callback)` method and registering via `nodemailer.createTransport()`.

```javascript
import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  name: 'mailapi',
  version: '1.0.0',
  send: (mail, callback) => {
    mail.normalize((error, data) => {
      if (error) return callback(error);
      // Adapter converts normalized data to OutboundMessageRequest
      // and sends POST /v1/messages
    });
  }
});
```

For an API-based transport, `mail.normalize()` applies transport defaults and
resolves content sources before mapping. The resulting `data` object maps as
follows:

| Normalized Nodemailer property | Mail API field | Mapping |
| --- | --- | --- |
| `from` | `from` | Parse formatted address string (`"Name <user@domain>"`) or `{ name, address }` object into an `EmailAddress`. |
| `to`, `cc`, `bcc` | `to`, `cc`, `bcc` | Normalize address strings, comma-separated lists, or arrays into `EmailAddress` objects. |
| `replyTo` | `replyTo` | Direct list correspondence. |
| `subject` | `subject` | Direct string correspondence. |
| `text`, `html` | `text`, `html` | Preserve both body alternatives. Buffers are decoded to UTF-8 strings. |
| `headers` | `headers` | Convert key-value maps or header arrays to ordered `headers` objects. |
| `attachments` | `attachments` | Resolve string, Buffer, or Stream contents and encode to Base64 with filename and content type. |

The transport invokes
`callback(null, { messageId: response.id, response: '202 Accepted' })`
upon receiving HTTP `200` or `202`. On HTTP error responses, it constructs an
appropriate `Error` instance and invokes `callback(err)`.

## Differences and limits

- Mail API `202` indicates asynchronous acceptance, while `200` indicates
  completion within an applied wait. Nodemailer's callback or promise resolves
  upon successful HTTP submission, which does not guarantee final recipient
  delivery.
- Nodemailer supports Node.js `Readable` streams and file paths for attachments.
  `mail.normalize()` resolves these content sources; because Mail API requires
  in-payload Base64 content, the transport must then encode the resolved bytes
  before dispatching the HTTP request.
- Inline attachments with `cid` properties have no structured equivalent in Mail
  API `v1`. The transport must reject the submission or transform both the HTML
  references and attachments together; removing only the `cid` would emit broken
  image links.
- Idempotency keys can be supplied via custom transport options or Nodemailer
  message headers, allowing safe retries over HTTP without duplicate execution.
