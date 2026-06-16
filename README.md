# pgrls-docs

Public docs site for [pgrls](https://github.com/pgrls/pgrls) — the
static analyzer for Postgres Row-Level Security.

Live at **https://pgrls.github.io/pgrls-docs/**.

## Layout

- `index.md` — landing page.
- `comparisons/` — pgrls vs adjacent tools (sqlfluff, Atlas, Semgrep,
  CodeQL, Snyk, squawk) and ecosystem positioning (Supabase,
  PostgREST, Hasura).
- `_config.yml` — Jekyll + [Just the Docs](https://just-the-docs.com)
  remote theme.

## Editing

Pages are plain Markdown with Jekyll front matter
(`title` / `parent` / `nav_order`). Pushes to `main` rebuild via
GitHub Pages automatically — no local Jekyll required for content edits.

For local preview:
```bash
bundle install
bundle exec jekyll serve --baseurl ""
```

## Where things live

| Concern | Repo |
| --- | --- |
| Linter source + product docs (README, Quickstart, recipes, AGENTS) | [pgrls/pgrls](https://github.com/pgrls/pgrls) |
| Public docs site (you are here) | [pgrls/pgrls-docs](https://github.com/pgrls/pgrls-docs) |
| GitHub Action (Marketplace) | [pgrls/pgrls-action](https://github.com/pgrls/pgrls-action) |
| Marketing collateral (launch posts, etc.) | `pgrls-marketing` (private) |
