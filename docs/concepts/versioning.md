---
title: "Versioning policy"
---

Mail API has separate repository-release and API-contract versions.

| Version | Source of truth | Purpose |
| --- | --- | --- |
| Repository release | Git tag and GitHub Release | Identifies every published repository revision, including documentation-only releases. |
| API contract | `openapi.yaml` `info.version` and URL path | Identifies the HTTP API clients call. |

Repository releases are created manually with a Semantic Version Git tag and a
GitHub Release. For example, release `v0.1.1` identifies a published repository
revision independently of the API specification version.

`info.version` is the API contract label, not the repository release version.
OpenAPI requires it to be a string but does not require Semantic Versioning.
The current contract is `v1` and is served under `/v1/`.

## Compatibility rule

A documentation-only release uses the next repository tag but leaves
`openapi.yaml` `info.version` unchanged. A specification change receives the
appropriate repository release. Compatible additions and clarifications remain
under `v1` and `/v1/` while the repository is pre-1.0. Breaking changes are
permitted during that phase and must be described in the appropriate repository
release notes. A future stable API release defines the compatibility and path
versioning rules for subsequent breaking changes.

Before repository release 0.5 there is no separate changelog file. The release
notes are the record of what changed, and a breaking change must be labelled
there.

## What counts as breaking

While the repository is pre-1.0 these changes are permitted, but they must be
labelled as breaking:

- Removing or renaming a field, or making an optional field required.
- Changing the status code for an existing outcome.
- Changing a registered [problem type](/problems/) URI or its meaning.
- Narrowing a value's accepted range or format.

These changes are not breaking:

- Adding an optional field, a new problem type, or a new response header.
- Adding a new operation.
- Adding a member to `extensions`, which is provider-defined by design.
- Clarifying prose without changing the contract.

## Stability of problem types

Registered problem type URIs are part of the contract. Because clients match on
`type` rather than status code alone, changing one is a breaking change even if
the status code stays the same. New conditions get new URIs instead of
redefining existing ones.
