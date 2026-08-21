# Versioning policy

`openapi.yaml` `info.version` is the repository release version and uses
Semantic Versioning without a leading `v`. The release workflow prefixes it
with `v` when creating the Git tag and GitHub Release. For example,
`info.version: 0.1.1` creates `v0.1.1`.

The HTTP API path follows the repository major version:

| Repository release | API path |
| --- | --- |
| `v0.0.0` through `v1.x.x` | `/v1/` |
| `v2.x.x` | `/v2/` |

The current endpoint is:

```text
POST /v1/messages
```

New releases within the same path version should preserve compatibility for
clients of that path. A breaking HTTP API change requires the next API path and
the corresponding repository major release. Release notes should describe any
migration between path versions.
