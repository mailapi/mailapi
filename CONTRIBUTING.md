# Contributing

Mail API is a specification repository. It contains `openapi.yaml`, the
documentation site that renders it, and the compatibility assessments — no mail
server, provider adapter, or SDK.

## Local setup

Node.js 22 is the supported version, matching CI.

```sh
npm ci
```

## Checks

Run everything CI runs:

```sh
npm run check
```

That is the two lint steps plus the build:

| Command | What it checks |
| --- | --- |
| `npm run lint:openapi` | `openapi.yaml` against Redocly's recommended ruleset. Exceptions live in `redocly.yaml`, each with the reason it does not apply. |
| `npm run lint:markdown` | Markdown style and the 80-column prose wrap. Configured in `.markdownlint-cli2.jsonc`. |
| `npm run build` | Builds the site. `starlight-links-validator` fails the build on a broken internal link or heading anchor. |

Use `npm run dev` for a local preview.

Note that `docs/` is the content collection: `src/content/docs` is a symlink to
it. Edit files under `docs/`, never under `src/content/docs/`.

## Changing the specification

`openapi.yaml` is the contract. When you change it:

1. Keep the response list in numeric order.
2. Use a problem `type` from the registry in `docs/problems.md`. A new
   condition needs a new entry there, not a reused URI.
3. Update the response table in `docs/index.md` if you add or remove a status
   code. It is the single source of truth; `README.md` links to it rather than
   repeating it.
4. Reflect the change in the affected compatibility assessments. A new status
   code usually needs a row in each `docs/compatibility/clouds/*.md` mapping
   table.
5. Describe a breaking change in the release notes, using the
   [breaking-change list](docs/concepts/versioning.md) to decide whether it is
   one. The repository keeps no changelog file before release 0.5.

Adding a documentation page is enough to get it into the sidebar for
`examples/`, `implementations/`, and `compatibility/*`, which autogenerate. A
new top-level page needs an entry in `astro.config.mjs`. API reference sidebar
entries are generated from `openapi.yaml`; do not hardcode operation links.

## Adding a compatibility assessment

`docs/compatibility/` has one directory per kind of thing being assessed. The
first two are about which side of the Mail API boundary a system sits on; the
last four are about the layer a caller-side adapter attaches to. Pick the
directory by answering its question, not by which language is involved.

| Directory | Question it answers |
| --- | --- |
| `clouds/` | Is it a provider Mail API would sit in front of? |
| `protocols/` | Is it a wire protocol, not an implementation? |
| `languages/` | Does the mail facility ship with the language, with no added dependency? |
| `libraries/` | Is it a dependency that composes or sends mail, usable without an application framework? |
| `frameworks/` | Does an application framework own the mail configuration and expose a swappable transport or sender? |
| `applications/` | Is it a deployed product whose mail hook an extension replaces? |

One system can occupy two of these, and that is not duplication: Jakarta Mail
is the library and Spring is the framework hook over it, so each gets a page
and the framework page links to the library's mapping table instead of
repeating it. A language with no built-in mail facility, such as Java or Rust,
correctly has no `languages/` page.

Sidebar labels follow the directory. `languages/` leads with the language
(`Python email`), `libraries/` leads with the library and puts the language in
parentheses (`Jakarta Mail (Java)`), and `frameworks/` and `applications/` use
the product name.

## Style

- Wrap prose at 80 columns. Reference links go on their own line with the
  description on a continuation line, so a long URL does not break the wrap.
- Use root-relative links inside `docs/` (`/compatibility/protocols/smtp/`),
  not relative `.md` paths. `README.md` uses absolute
  `https://mailapi.github.io/` URLs because it is read outside the site.
- Keep the distinction the assessments rely on: provider *acceptance* is not
  recipient *delivery*, and an adapter's own credential failure is a `500`, not
  a caller error.

## Releases

Releases are manual: create a Semantic Version Git tag and a GitHub Release.
Publishing a release triggers `.github/workflows/publish-pages.yml`, which
builds the site and pushes it to the `mailapi/mailapi.github.io` repository.

Repository release versions and the API contract version are independent. See
the [versioning policy](docs/concepts/versioning.md).
