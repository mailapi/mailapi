# Send a message

Submit an outbound message to `POST /v1/messages`. `Idempotency-Key` is
optional, but using a client-generated value makes retries of the same payload
safe for 24 hours.

```http
POST https://api.example.com/v1/messages HTTP/1.1
Content-Type: application/json
Idempotency-Key: welcome-user/123456 # optional

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

## Failure response

Failures use `application/problem+json`. For example, a message with
semantically invalid fields returns `422 Unprocessable Content`.

```http
HTTP/1.1 422 Unprocessable Content
Content-Type: application/problem+json

{
  "type": "https://api.example.com/problems/invalid-message",
  "title": "Message fields are invalid",
  "status": 422,
  "detail": "At least one recipient address is invalid.",
  "instance": "/v1/messages/requests/01HZXKJ42P6X0Q7J9ZMY1P4R8B"
}
```

See the [submission response table](../../README.md#submission-responses) for
the other success and failure status codes.

