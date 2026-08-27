---
title: "Send a message"
sidebar:
  order: 1
---

Submit an outbound message to `POST /v1/messages`.

A submission requires `from`, at least one recipient across `to`, `cc`, and
`bcc`, and at least one body representation (`text`, `html`, or both).

To safely retry a request, clients can optionally add an `Idempotency-Key`
header with a client-generated value. It makes retries of the same payload safe
for 24 hours; omit it when idempotent retry handling is unnecessary.

```http
POST https://api.example.com/v1/messages HTTP/1.1
Content-Type: application/json
Authorization: Bearer <token>
Idempotency-Key: welcome-user/123456

{
  "from": {
    "email": "noreply@example.org",
    "name": "Example App"
  },
  "to": [
    {
      "email": "user@example.net",
      "name": "Example User"
    }
  ],
  "replyTo": [
    {
      "email": "support@example.org",
      "name": "Support"
    }
  ],
  "subject": "Welcome to Example App",
  "text": "Hello, welcome to Example App.",
  "html": "<p>Hello, welcome to <strong>Example App</strong>.</p>",
  "headers": [
    {
      "name": "X-App",
      "value": "example"
    }
  ],
  "attachments": [
    {
      "filename": "terms.txt",
      "contentType": "text/plain",
      "content": "VGVybXMgYW5kIGNvbmRpdGlvbnMu"
    }
  ]
}
```

When the provider accepts the message for asynchronous processing, it returns
`200 OK`. This does not confirm delivery to the recipient.

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": "msg_01HZXKJ42P6X0Q7J9ZMY1P4R8B"
}
```

## Replayed response

Retrying with the same `Idempotency-Key` and a byte-for-byte identical body
replays the stored terminal outcome rather than sending a second message. The
replay is marked with `Idempotency-Replayed`.

```http
HTTP/1.1 200 OK
Content-Type: application/json
Idempotency-Replayed: true

{
  "id": "msg_01HZXKJ42P6X0Q7J9ZMY1P4R8B"
}
```

A terminal `500` is also stored and replayed. Preflight failures such as `400`,
`401`, `403`, `413`, `415`, `422`, and `429` are not stored, so a corrected
request can reuse the same key. See [idempotency](/concepts/idempotency/) for
the processing order and conflict behavior.

## Failure response

Failures use `application/problem+json`. For example, a message with
semantically invalid fields returns `422 Unprocessable Content`.

```http
HTTP/1.1 422 Unprocessable Content
Content-Type: application/problem+json

{
  "type": "https://mailapi.github.io/problems/invalid-message",
  "title": "Message fields are invalid",
  "status": 422,
  "detail": "At least one recipient address is invalid.",
  "instance": "/v1/messages/requests/01HZXKJ42P6X0Q7J9ZMY1P4R8B"
}
```

The `type` member is a stable identifier owned by this specification, so a
client can match the condition across providers. See the
[problem type registry](/problems/) for the full list and the
[submission response table](/concepts/responses/) for the other status codes.
