# Versioning policy

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
under `v1` and `/v1/`. A breaking HTTP API change requires `info.version: v2`
and `/v2/`. Release notes should describe any migration between path versions.
