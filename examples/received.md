# Received message

An inbound message is represented by an `InboundMessage` wrapper. It adds the
Mail API record ID and receipt timestamp around the same core message model
used for outbound submission. Mail API `v1` does not yet define an inbound
retrieval endpoint; the following `200 OK` response illustrates how a
host-defined or future endpoint can return this representation.

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": "msg_01HZXKJ42P6X0Q7J9ZMY1P4R8B",
  "receivedAt": "2026-08-21T10:55:00Z",
  "message": {
    "from": {
      "email": "sender@example.net",
      "name": "Sender Name"
    },
    "to": [
      {
        "email": "inbox@example.org",
        "name": "Inbound Inbox"
      }
    ],
    "cc": [
      {
        "email": "team@example.org",
        "name": "Team"
      }
    ],
    "subject": "Question about order #12345",
    "text": "Hi, I have a question about my order.",
    "html": "<p>Hi, I have a question about my order.</p>",
    "headers": [
      {
        "name": "Message-ID",
        "value": "<abc123@example.net>"
      },
      {
        "name": "Received",
        "value": "from mx1.example.net by mx2.example.org; Fri, 21 Aug 2026 10:54:56 +0000"
      },
      {
        "name": "Received",
        "value": "from app.example.net by mx1.example.net; Fri, 21 Aug 2026 10:54:52 +0000"
      }
    ],
    "attachments": [
      {
        "filename": "details.txt",
        "contentType": "text/plain",
        "content": "T3JkZXIgZGV0YWlscy4="
      }
    ]
  }
}
```

