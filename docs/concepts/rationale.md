---
title: "Design rationale"
---

This page records `v1` decisions that are not self-evident from the
specification, so an implementer can tell a deliberate choice from an
oversight.

## `202 Accepted` by default, with bounded waiting

`POST /v1/messages` normally returns `202 Accepted`. The provider has accepted
the request for asynchronous submission processing, but that processing need
not have completed when the response is sent. Neither `202` nor any later
submission result confirms delivery to a recipient.

A client that benefits from an in-band completion result can send the
[RFC 7240](https://www.rfc-editor.org/rfc/rfc7240) preference:

```http
Prefer: wait=10
```

This asks the provider to wait up to ten seconds for submission to complete.
Preferences are optional: a provider may ignore `wait`, in which case it
returns the normal `202` response. When the provider applies it, the response
includes:

```http
Preference-Applied: wait=10
```

If submission completes within that period, the provider can return `200 OK`.
If the period expires first, it returns `202 Accepted` and continues
asynchronously. `wait` is a latency preference, not a delivery timeout and not
a guarantee that the server will wait for the requested duration.

RFC 7240 also defines `respond-async`, but Mail API does not need clients to
request asynchronous handling: asynchronous handling is already the default.
The useful preference at this boundary is the optional bounded wait.

## Why the two success responses mean different things

[RFC 9110](https://www.rfc-editor.org/rfc/rfc9110#section-15.3.3) defines `202`
for a request accepted for processing whose processing has not completed. That
is the default Mail API path. The `id` in the response correlates the accepted
submission; it is not a delivery receipt or a status-resource URL.

`200` means the submission operation itself completed. It is normally returned
while a request is held open under an applied wait. It can also be replayed
after a keyed submission that initially returned `202` reaches its terminal
success result. It still reports only provider acceptance, not final recipient
delivery. Store-and-forward delivery, bounces, webhooks, and delivery-status
resources remain outside `v1`.

The distinction is therefore:

| Response | Submission execution | Recipient delivery |
| --- | --- | --- |
| `202 Accepted` | Accepted and may still be running | Unknown and out of scope |
| `200 OK` | Completed; provider accepted responsibility | Unknown and out of scope |

## Provider and protocol implications

SMTP reports successful handoff with `250` after message content, while JMAP
represents submission state in `EmailSubmission`. Cloud APIs vary: Amazon SES,
Gmail, and Resend answer successful send calls with `200`; Azure Communication
Services Email and SendGrid answer with `202`.

An adapter does not copy the upstream HTTP status mechanically. Without an
applied Mail API `wait` preference it returns Mail API `202`, even when an
upstream call completed before the response. With an applied wait preference,
it can return `200` once the upstream submission boundary has succeeded. It
must never wait for final recipient delivery.

## Idempotency consequences

An initial `202` is not a terminal stored outcome. While keyed execution is
still running, a matching retry returns the defined `409` in-progress problem.
Once execution reaches terminal `200` or `500`, that outcome is stored and a
matching retry replays it. This allows retry safety without treating
asynchronous acceptance as completion.

Without an `Idempotency-Key`, the identifier in a `202` response provides
correlation only; `v1` defines no operation that retrieves its later status.
A future status capability can add such an operation without changing the
meaning of either success response.

Because `202` can be returned before a downstream provider assigns its own
identifier, Mail API assigns its `id` before asynchronous execution begins. An
adapter retains that ID across terminal replays and records any SES, JMAP,
Resend, or other downstream identifier as an internal correlation rather than
changing the public ID.
