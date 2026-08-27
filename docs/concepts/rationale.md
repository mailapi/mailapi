---
title: "Design rationale"
---

This page records `v1` decisions that are not self-evident from the
specification, so an implementer can tell a deliberate choice from an
oversight. Each entry states the arguments that lost, not only the ones that
won.

## `200 OK` rather than `202 Accepted`

`POST /v1/messages` returns `200`. An earlier pre-1.0 draft returned `202`.

At the moment it answers, a provider knows two things: it durably accepted
responsibility for the message, and it issued an identifier for that
submission. It does not know whether any recipient will receive the message.
The question is which status code states exactly that and nothing more.

### Where this API's scope ends

`v1` defines a submission boundary and nothing beyond it: no delivery-status
operation, no bounce model, no webhook, no message resource to retrieve. The
request is "accept this message for sending". Once the provider has accepted
it, **that request is complete**. No part of it is still outstanding as far as
this API is concerned.

[RFC 9110](https://www.rfc-editor.org/rfc/rfc9110#section-15.3) defines `202`
for a request where "the processing has not been completed", and adds that the
response "ought to describe the request's current status and point to (or
embed) a status monitor". `v1` has no status monitor and promises none.
Answering `202` would describe an unfinished lifecycle that the specification
deliberately does not expose — "we will finish this later", where the accurate
statement is "the submission is finished; delivery is out of scope and will not
be reported here". Using `202` to mean *we will never tell you* inverts the
purpose of the code.

The same section defines `200` for a request that has succeeded, and for `POST`
it specifies the content as "a representation of the status of, or results
obtained from, the action". The `{ "id": ... }` body is precisely that: the
status of the submission, and the identifier the provider issued for it. `200`
does not claim that a downstream effect has occurred; it claims the request
succeeded, which it did.

### What email's own protocols do

- **SMTP** replies `250` after `DATA` when the next hop takes responsibility for
  onward delivery. SMTP has no separate acceptance code: its ordinary success
  reply *is* acceptance, because store-and-forward mail has never confirmed
  delivery in band. Delivery status arrives later as a separate message, if at
  all. See the [SMTP assessment](/compatibility/protocols/smtp/).
- **JMAP** answers a successful method batch with HTTP `200`, including a batch
  whose `EmailSubmission/set` failed; the failure is an object inside that
  `200`. State lives in the resource: `EmailSubmission` carries `undoStatus`
  for the submission lifecycle and an optional `deliveryStatus` for
  per-recipient delivery. So the modern IETF mail-submission protocol over
  HTTP puts even delivery state in an object rather than in the submit call's
  status code, which is the division this contract makes. See the
  [JMAP assessment](/compatibility/protocols/jmap/).

IMAP and POP3 do not bear on this decision; they are mailbox access rather than
submission.

### What providers return

| Provider | Success status | Mail API |
| --- | --- | --- |
| [Amazon SES](/compatibility/clouds/amazon-ses/) `SendEmail` | `200` with `MessageId` | `200` |
| [Azure Communication Services Email](/compatibility/clouds/azure-email/) | `202` with `Operation-Location` and an operation ID | `200` |
| [Gmail API](/compatibility/clouds/gmail-api/) `users.messages.send` | `200` with a message resource | `200` |
| [Resend](/compatibility/clouds/resend/) `POST /emails` | `200` with an email `id` | `200` |
| [SendGrid](/compatibility/clouds/sendgrid/) `POST /v3/mail/send` | `202` with an empty body and an `X-Message-Id` header | `200` |

Three return `200` and two return `202`, so this is a split market rather than
a settled convention, and a headcount cannot decide the question. The two `202`
cases are not the same case, and the difference is the whole point.

Azure returns `202` **and** supplies `Operation-Location` together with a
get-send-result operation. It earns the code by providing exactly the status
monitor RFC 9110 asks for.

SendGrid returns `202` with an empty body, an identifier in the `X-Message-Id`
header, and no per-submission status resource anywhere — the same position this
contract is in. SendGrid is therefore the strongest evidence against the choice
made here: a widely used submission API answers `202` while promising no
completion it will ever report.

It does not change the outcome, because the scope argument above does not depend
on what providers do. But it narrows the claim honestly: `202` is defensible in
this space, and `200` here is a judgment about which statement is more accurate,
not a correction of an industry-wide error. What SendGrid's response gives a
client is in fact less than a Mail API `200` gives one — no identifier in the
body, nothing to poll, and a status code whose implied later completion never
arrives.

Note also what the table does not show. None of the five returns a delivery
confirmation. Every one of them reports acceptance, which is what the Mail API
`200` reports as well.

### What the calling side can observe

Every host mail abstraction assessed here collapses a send result to success or
failure:

- A boolean: [`wp_mail()`](/compatibility/applications/wordpress/),
  [PHP `mail()`](/compatibility/languages/php/),
  [Drupal `MailInterface::mail()`](/compatibility/applications/drupal/).
- Void plus an exception:
  [Jakarta Mail `Transport.send()`](/compatibility/libraries/jakarta-mail/),
  [Spring `send()`](/compatibility/frameworks/spring/), a
  [Symfony Mailer transport](/compatibility/libraries/symfony-mailer/).
- A status object or an event:
  [MediaWiki `StatusValue`](/compatibility/applications/mediawiki/),
  [lettre `Response`](/compatibility/libraries/lettre/),
  [Laravel `MessageSent`](/compatibility/frameworks/laravel/).

Not one of them can represent "accepted but not delivered" differently from
"delivered", and the retry guidance is identical for `200` and `202`. So the
choice changes no adapter's behavior and no caller's control flow. It decides
only which claim the contract makes.

### The case for `202`, and why it lost

The argument was that a vendor-neutral mail API should encode
acceptance-is-not-delivery in the machine-readable part of the contract instead
of repeating it in prose, so that a client checking only the status code cannot
conclude delivery.

It failed on three counts.

1. **It reaches no one.** Every assessed host collapses the result to a boolean
   or a void return, so no caller can observe the difference between `200` and
   `202`. The misreading it was meant to prevent is not prevented, because
   `202` also reads as success to anything testing for `2xx`.
2. **It states the wrong thing.** `202` means processing continues. `v1` means
   the submission is done and delivery is not this API's to report. Those are
   different claims, and only one of them is true here.
3. **It contradicts the precedent.** Both of email's own submission protocols,
   SMTP and JMAP, put acceptance under plain success.

The invariant survives where it can be enforced: the operation description, the
[submission response table](/concepts/responses/), the `id` documented as an
accepted-message identifier for correlation rather than a receipt, and every
compatibility assessment.

### Consequences an implementer must accept

- A `200` is acceptance. An adapter must not wait for terminal delivery before
  responding; polling a provider's delivery-status API first would contradict
  the response it then returns.
- The `id` is a correlation identifier. It is not a receipt, and it does not
  promise that a later status lookup will succeed.
- `v1` defines no delivery-status, bounce, or webhook operation, so a `200`
  promises no subsequent notification. That remains a deployment concern.
- An Azure adapter narrows a provider `202` to `200`. Only the status code
  narrows: the operation ID still surfaces as the accepted-message `id`. The
  adapter must not present `Operation-Location` as though Mail API defined it.
- If a later version adds a delivery-status resource, it arrives as a new
  operation or response header, which the
  [versioning policy](/concepts/versioning/) treats as a compatible addition. Choosing
  `202` now would not have been required for that, whereas changing the success
  status code later would be breaking.

### Rejected alternatives

- **`200` with a `status: "accepted"` member**, following JMAP's habit of
  keeping state in the payload. In `v1` that member would be a constant with no
  other possible value, so it would carry no information from the day it was
  specified.
- **`201 Created`**, which would require a created resource the client can
  refer to. `v1` defines no message retrieval operation and therefore nothing
  to name in `Location`.
