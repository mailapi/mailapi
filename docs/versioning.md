# Versioning policy

Mail API has separate repository-release and API-specification versions.

| Version | Source of truth | Purpose |
| --- | --- | --- |
| Repository release | Git tag and GitHub Release | Identifies every published repository revision, including documentation-only releases. |
| API specification | `openapi.yaml` `info.version` | Identifies the OpenAPI contract revision. It changes only when that contract changes. |

Repository releases are created manually with a Semantic Version Git tag and a
GitHub Release. For example, release `v0.1.1` identifies a published repository
revision independently of the API specification version.

`openapi.yaml` `info.version` also uses Semantic Versioning. Its public
compatibility label uses the major and minor components: `1.0.0` is **Spec
v1.0** and `1.1.0` is **Spec v1.1**.

## Repository, specification, and path relationship

| Repository release | Specification version | API path |
| --- | --- | --- |
| `v0.0.0` through `v1.0.x` | Spec v1.0 (`1.0.0`) | `/v1/` |
| `v1.1.0` through `v1.1.x` | Spec v1.1 (`1.1.0`) | `/v1/` |
| `v1.2.0` through `v1.2.x` | Spec v1.2 (`1.2.0`) | `/v1/` |

The current endpoint is:

```text
POST /v1/messages
```

A documentation-only release uses the next repository tag but leaves
`openapi.yaml` `info.version` unchanged. A specification change receives the
appropriate repository release and updates the specification version according
to this table. New Spec v1 minor releases remain on `/v1/`; a breaking HTTP API
change requires Spec v2 and `/v2/`. Release notes should describe any migration
between path versions.
