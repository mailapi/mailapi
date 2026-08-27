---
title: "Spring compatibility"
sidebar:
  label: Spring
---

This assessment compares Mail API with Spring's pluggable
`org.springframework.mail.javamail.JavaMailSender` abstraction. A potential
Mail API adapter would supply its own sender bean, receive the composed
`MimeMessage`, and submit an `OutboundMessageRequest` to `POST /v1/messages`.

See the [JavaMailSender reference](https://docs.spring.io/spring-framework/reference/integration/email.html).

## Potential adapter boundary

The adapter belongs at the `JavaMailSender` bean, not at individual call sites.
Spring Boot's mail auto-configuration backs off when the application supplies
its own sender bean, so registering a `@Bean` is enough to redirect every
`send()` in the application. Callers that use `MimeMessagePreparator` or
`MimeMessageHelper` keep working, because they operate on the `MimeMessage` the
sender hands them.

Spring exposes two source models, and they map to Mail API with different
fidelity.

| Spring input | Mail API field | Mapping |
| --- | --- | --- |
| `SimpleMailMessage` `from`, `to`, `cc`, `bcc`, `replyTo` | `from`, `to`, `cc`, `bcc`, `replyTo` | Parse each address string into an `EmailAddress`. |
| `SimpleMailMessage.subject` | `subject` | Copy as-is. |
| `SimpleMailMessage.text` | `text` | Plain text only; `SimpleMailMessage` has no HTML representation, so `html` stays absent. |
| `SimpleMailMessage.sentDate` | — | No `v1` field. The provider stamps the message; an adapter should not synthesize a `Date` header from it silently. |
| `MimeMessage` built through `MimeMessageHelper` | Full message model | Follow the [Jakarta Mail mapping](/compatibility/libraries/jakarta-mail/), which is the model Spring composes into. |

## Configuration and error mapping

- `spring.mail.host`, `spring.mail.port`, and the `spring.mail.username` and
  `spring.mail.password` pair describe an SMTP endpoint and have no HTTP
  equivalent. A Mail API sender needs its own property namespace for the base
  URL, the bearer token, and idempotency behavior.
- `send()` returns nothing and signals failure by throwing `MailException`.
  Mail API's defined responses map onto its existing subtypes:
  `401` and `403` to `MailAuthenticationException`, a rejected payload to
  `MailSendException`, and an adapter that cannot build the request at all to
  `MailParseException`. Reusing the established types keeps existing `catch`
  blocks correct.

## Differences and limits

- A Mail API `200` is provider acceptance, not recipient delivery. Wrapping
  `send()` in `@Async` or a retry advice does not change that; a retry after a
  `200` is a duplicate submission unless it carries the same
  `Idempotency-Key`.
- The Actuator mail health indicator probes the SMTP connection of Spring's own
  sender implementation. An HTTP-backed sender needs its own readiness signal,
  or must disable that indicator, rather than reporting a mail-server check it
  never performs.
- `MimeMessageHelper.addInline()` produces content-ID references. Mail API `v1`
  has no inline-embed field, so the adapter needs an explicit policy, such as
  rejecting inline parts, rather than silently emitting broken HTML.
- Inbound Mail API examples do not provide a Spring inbound-mail feature or
  callback endpoint. Spring Integration's inbound mail adapters read mailboxes
  over IMAP or POP3, which is the separate boundary covered by the
  [IMAP](/compatibility/protocols/imap/) and
  [POP3](/compatibility/protocols/pop/) assessments.
