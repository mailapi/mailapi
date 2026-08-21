# Mail API spec

**Mail API is a vendor-neutral API specification for sending and receiving email.**

## Why this exists

Applications such as MediaWiki or WordPress should be able to send and receive email without being tied directly to one provider. This project defines a shared API shape that can be implemented by different providers.

This repository contains the specification only. It does not contain a mail server, provider adapters, SDKs, or application plugins.

## MVP HTTP API

The initial MVP defines a single outbound endpoint:

`POST /v1/messages`

Example request body:

```json
{
  "from": { "email": "noreply@example.org", "name": "Example App" },
  "to": [{ "email": "user@example.net", "name": "Example User" }],
  "subject": "Welcome",
  "text": "Hello from Mail API"
}
```

A successful response returns a message identifier:

```json
{
  "messageId": "msg_01HZXKJ42P6X0Q7J9ZMY1P4R8B"
}
```

## Message model

The core message model follows established RFC 5322/MIME concepts where practical, including addresses, headers, body content, and attachments. The same model is used for outbound and inbound messages (see `examples/send.json` and `examples/inbound.json`).

## Future transports

The core model is transport-agnostic. Additional transports, such as gRPC, may be defined later without changing the message model.
