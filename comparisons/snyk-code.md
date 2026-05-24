---
title: "vs Snyk Code"
parent: Comparisons
nav_order: 60
permalink: /comparisons/snyk-code/
---

# pgrls vs. Snyk Code

**Different artifacts. Coexistence, not competition.**

[Snyk Code](https://snyk.io/product/snyk-code/) is **commercial,
dev-focused SAST** — scans source code for security vulnerabilities,
prioritises by risk, and offers auto-fix suggestions. It integrates
into PRs, IDEs, and CI/CD. Its rule coverage is the conventional
app-sec set (taint analysis, injection, deserialization, dependency
confusion, etc.); Snyk Code's public documentation does **not list any
out-of-the-box rules for Postgres Row-Level Security policies.**

**pgrls** is a Postgres Row-Level Security linter that runs against a
live database catalog. It analyses every policy's `USING` and
`WITH CHECK` predicates as ASTs and flags the semantic bugs that get
past code review.

The two don't compete. Snyk Code asks *"is the calling application
code safe?"* pgrls asks *"does the database refuse to return the wrong
rows when the application code messes up?"*

## At a glance

|                          | Snyk Code                                         | pgrls                                                  |
| ------------------------ | ------------------------------------------------- | ------------------------------------------------------ |
| Scope                    | Application source code (SAST)                    | Live Postgres database                                 |
| Cost model               | Commercial (per-developer SaaS)                   | MIT-licensed open source                               |
| RLS coverage             | None documented                                   | 43 rules tuned to RLS                                  |
| Auto-fix                 | "DeepCode AI" suggestions for many rules          | 12 of 43 rules, emit `.sql` migration                  |
| Where the bug is found   | In the code that talks to the database            | In the database that enforces access                   |
| Output                   | Snyk dashboard, PR comments, IDE                  | SARIF / JSON / GH annotations / Markdown / JUnit / text |
| CI integration           | Snyk CLI in pipeline, GitHub App                  | GitHub Action, pre-commit                              |

## What Snyk Code does that pgrls does not

- **Application-layer security across many languages** — taint
  analysis for injection, hardcoded secrets, deserialization,
  authentication issues in the calling code.
- **Dev-workflow polish** — IDE inline suggestions, PR-blocking
  policy, risk prioritisation across an organisation's portfolio.
- **Cross-tool security platform** (Snyk Open Source for SCA, Snyk
  Container, Snyk IaC) for teams standardised on Snyk.

## What pgrls does that Snyk Code does not

- **Reads live database state.** Snyk Code looks at source files;
  pgrls looks at the actually-enforced policy catalogue, including
  what an ORM or hot-fix applied without going through migration
  source control.
- **AST-level reasoning about RLS predicates** — catches
  `auth.uid() IS NULL OR …` (SEC004), missing per-user scoping
  (SEC027), nullable discriminator columns (SEC030), and 40 other
  RLS-specific bugs.
- **Mechanical auto-fix for RLS** — emits `DROP POLICY` /
  `CREATE INDEX` SQL ready for the next migration.
- **Semantic policy-diff** with access-widening classification
  (`pgrls diff`).
- **`pgrls.testing`** pytest plugin for RLS isolation tests.

## Use them together

Two distinct layers of the same defence-in-depth:

- **Snyk Code** flags an SQL-injection or auth-bypass pattern in the
  application code that *talks to* the database.
- **pgrls** flags whether the database's RLS policies actually
  enforce the access control the application code assumed.

Either tool catching its finding without the other still leaves the
opposite layer exposed.

## Honest summary

If a team already runs Snyk Code, pgrls slots in next to it (same
SARIF output → same Code Scanning dashboard, or wire to Snyk's
custom-find ingestion). The two ask different questions of different
artifacts.
