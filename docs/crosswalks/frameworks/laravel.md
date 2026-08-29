---
title: "Laravel crosswalk"
sidebar:
  label: Laravel
---

This crosswalk compares Mail API with Laravel's mail
abstraction. Laravel sends through Symfony Mailer, so the message mapping is
the same one the
[Symfony Mailer crosswalk](/crosswalks/libraries/symfony-mailer/)
describes. What Laravel adds is the framework's own registration and
configuration hook, which is where an adapter attaches.

See Laravel's [custom transports documentation](https://laravel.com/docs/12.x/mail#custom-transports).

## Potential Laravel transport registration

Register the Mail API transport through `Mail::extend()`, configure it as a
named mailer in `config/mail.php`, and select it as the default mailer or for
individual messages. Registering a transport is preferable to intercepting
individual messages: `Mailable` rendering, Markdown mail, and attachment
handling all complete before the transport receives the message.

Laravel queueing remains unchanged. Queued jobs invoke the selected transport
when they run, so a queued mailable and a synchronous one produce the same
Mail API request.

## Differences and limits

- Mail API `202` is asynchronous acceptance and `200` is completion within an
  applied wait. Laravel's `MessageSent` event and the `Mail::assertSent()` test
  helpers map either success to a sent result, so neither confirms recipient
  delivery.
- Laravel's `Mail::fake()` bypasses the transport entirely. It verifies that
  the application asked to send a mailable, not that a Mail API request is
  well-formed; an adapter needs its own tests at the transport boundary.
- Inline embedded attachments (`$message->embed()`) have no Mail API `v1`
  content-ID field. The transport needs an explicit policy, such as rejecting
  embeds, rather than silently emitting broken HTML.
- Credential issuance and rotation belong in `config/mail.php` and the
  environment, not in the transport. Mail API defines the `401` and `403`
  responses the transport must surface, not how a token is obtained.
