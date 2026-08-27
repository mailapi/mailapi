---
title: "Idempotency"
sidebar:
  label: Idempotency
---

To make a submission safe to retry, clients can supply an `Idempotency-Key`
header containing a unique 1–256 character key of visible ASCII characters. For
24 hours, a retry with the same key and byte-for-byte identical UTF-8 request
body replays the original outcome instead of submitting a duplicate message.
JSON whitespace and object-member ordering are significant.

- A replayed response repeats the status code and body of the original outcome,
  **including an unsuccessful one**. If the first submission returned `422`, a
  matching retry returns that same `422`.
- A replayed response carries `Idempotency-Replayed: true`. A newly processed
  submission omits the header.
- After 24 hours the key is forgotten. A later request reusing it is processed
  as a new submission.
- Reusing a key with a different body returns
  [`idempotency-key-reused`](/problems/); retrying while the matching
  submission is in progress returns
  [`idempotency-key-in-progress`](/problems/). Both use status `409`.
