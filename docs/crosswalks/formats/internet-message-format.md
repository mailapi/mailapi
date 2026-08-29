---
title: "Internet Message Format crosswalk"
sidebar:
  label: Internet Message Format
---

## Format role

Internet Message Format (RFC 5322) defines the syntax and semantics of
electronic mail messages (`.eml`), consisting of structured header fields and a
body. Multipurpose Internet Mail Extensions (MIME, RFC 2045–2049) extends this
format to support non-ASCII text, structured multipart alternatives
(`multipart/alternative`), and arbitrary file attachments (`multipart/mixed`).

Mail API `v1` provides a compact, structured JSON contract for submitting and
representing messages. This crosswalk specifies how a parser, gateway, or
adapter maps between raw RFC 5322/MIME streams and Mail API's
`OutboundMessageRequest` and `InboundMessage` models.

## References

- [RFC 5322: Internet Message Format](https://www.rfc-editor.org/rfc/rfc5322.html):
  core message syntax, header specifications, and mailbox definitions.
- [RFC 6854: Update to Internet Message Format](https://www.rfc-editor.org/rfc/rfc6854.html):
  updates allowing group syntax in `From` and `Sender` header fields.
- [RFC 6532: Internationalized Email Headers](https://www.rfc-editor.org/rfc/rfc6532.html):
  UTF-8 encoding in headers and address constraints.
- [RFC 2045: MIME Part One](https://www.rfc-editor.org/rfc/rfc2045.html):
  MIME headers, media types, and transfer encodings.
- [RFC 2046: MIME Part Two](https://www.rfc-editor.org/rfc/rfc2046.html):
  media types and multipart message tree structures.
- [RFC 2183: Content-Disposition Header Field](https://www.rfc-editor.org/rfc/rfc2183.html):
  attachment presentation information and filenames.

## Potential adapter boundary

An adapter parsing an RFC 5322/MIME message unfolds headers, decodes MIME
encoded-words (RFC 2047) and transfer encodings (Quoted-Printable, Base64), and
populates Mail API fields. Conversely, an adapter serializing an
`OutboundMessageRequest` into raw MIME constructs a compliant MIME tree.

| RFC 5322 / MIME concept | Mail API field | Mapping and limit |
| --- | --- | --- |
| `From` header | `from` | Mail API preserves a single author (`EmailAddress`). When RFC 5322 contains multiple authors or RFC 6854 group syntax, an adapter must select a primary author. |
| `Sender` header | — | RFC 5322 defines `Sender` when multiple authors exist or an agent transmits on behalf of an author; Mail API has no separate sender field. |
| `To`, `Cc` headers | `to`, `cc` | Parse address lists into `EmailAddress` arrays. Named group syntax must be flattened or omitted. |
| `Bcc` header | `bcc` | Preserved when present in authoring/submission contexts. RFC 5322 commonly strips `Bcc` before transfer. |
| `Reply-To` header | `replyTo` | Parse address list into `EmailAddress` objects. |
| `Subject` header | `subject` | Decode RFC 2047 encoded-words into a UTF-8 string. |
| `Date` header | `headers` | RFC 5322 date-time string preserved in `headers`. For inbound messages, provider receipt time maps to `InboundMessage.receivedAt`. |
| `Message-ID` header | `headers` | Retained in `headers`. The provider assigns its own distinct Mail API submission `id`. |
| `In-Reply-To`, `References` | `headers` | Preserved in `headers` to maintain message threading. |
| `text/plain` body part | `text` | Extract and decode character set and transfer encoding (e.g., 7bit, 8bit, Quoted-Printable). |
| `text/html` body part | `html` | Extract and decode HTML body from `multipart/alternative`. |
| Regular MIME attachments | `attachments` | Extract `multipart/mixed` parts with `Content-Disposition: attachment`, preserving filename, media type, and Base64 content. |
| Supplemental headers | `headers` | Retain unfolded headers in original order, excluding structured fields handled by dedicated properties. |

## Differences and limits

- **Multiple authors and `Sender`**: RFC 5322 permits `From: author1@...,
  author2@...` with an accompanying `Sender:` header. Mail API models exactly
  one visible author in `from`.
- **Group address syntax**: RFC 5322 and RFC 6854 allow mailbox groups (e.g.,
  `Staff: user1@example.org, user2@example.org;`). An adapter must flatten
  groups into standard mailbox addresses.
- **Flattened model vs general MIME trees**: Mail API models `text`, `html`, and
  regular `attachments`. Deeply nested multipart hierarchies,
  `multipart/related` with inline content IDs (`cid:`), `multipart/signed`, and
  encapsulated messages (`message/rfc822`) require explicit transformation or
  flattening policies.
- **Header unfolding and character sets**: RFC 5322 header lines may be folded
  across multiple lines with leading whitespace. Adapters must unfold headers and
  normalize them to single-line UTF-8 strings before creating JSON.
- **MIME transfer encoding**: Raw MIME uses `7bit`, `8bit`, `quoted-printable`,
  or `base64` transfer encodings. Mail API bodies (`text`, `html`) are always
  unencoded UTF-8 strings; binary attachments are always Base64.
