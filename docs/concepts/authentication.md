---
title: "Authentication"
sidebar:
  label: Authentication
---

A request carries a provider-issued bearer token:

```text
Authorization: Bearer <token>
```

A provider may document an equivalent scheme, but it must use the `401` and
`403` contract in the [submission response table](/concepts/responses/) so that
a client can distinguish "not authenticated" from "not allowed to send this".
Credential issuance, scoping, and rotation are deployment concerns.
