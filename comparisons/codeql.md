---
title: "vs CodeQL"
parent: Comparisons
nav_order: 50
permalink: /comparisons/codeql/
---

# pgrls vs. CodeQL

**Different abstraction levels. Composable in a Code Scanning pipeline.**

[CodeQL](https://github.com/github/codeql) is the **query-based SAST**
that powers GitHub Advanced Security and GitHub Code Scanning. It
supports C/C++, C#, Go, Java, JavaScript, Python, Ruby, and Rust;
queries are written in the CodeQL query language and ship as part of
GitHub Code Scanning's default suite. The standard library targets
*application-code* vulnerabilities (SQL injection / taint tracking,
unsafe deserialization, auth bypass, secret exposure) — there are
**no built-in queries for Postgres Row-Level Security policies.**

**pgrls** is a Postgres-specific Row-Level Security linter. It runs
against the database catalog and reasons about every RLS policy's
`USING` / `WITH CHECK` predicate AST. It emits SARIF (CodeQL's native
output format), so its findings render in **GitHub Code Scanning right
next to CodeQL's** — same dashboard, same review UI.

## At a glance

|                          | CodeQL                                                 | pgrls                                                  |
| ------------------------ | ------------------------------------------------------ | ------------------------------------------------------ |
| What it scans            | Source files in C/C++, C#, Go, Java, JS, Python, Ruby, Rust | Live Postgres database                            |
| RLS-specific queries     | None in the standard library                           | 43 rules tuned to RLS                                  |
| Where bugs are reported  | Application code                                       | Database catalog (policies, roles, views, triggers)    |
| Output format            | SARIF (Code Scanning native)                           | SARIF, plus text / JSON / Markdown / GH annotations / JUnit |
| Code Scanning integration | Built-in (it's the canonical engine)                  | `pgrls lint --format sarif` → `upload-sarif` action     |
| Custom queries           | CodeQL query language                                  | Python rule modules                                    |

## What CodeQL does that pgrls does not

- **Polyglot application-code security analysis** — taint tracking
  for SQL injection in eight ecosystems, dangerous-API detection,
  data-flow analysis across function and module boundaries.
- **GitHub Advanced Security platform integration** — push protection,
  custom-query packs, organization-wide scanning, security overview.
- **VS Code extension** for query authoring and exploring code in
  the CodeQL database model.
- **Catches the SQL injection that leads to a bypass** (caller-side),
  whereas pgrls catches the **policy** that fails to stop the bypass
  (database-side). Two layers of the same defence-in-depth.

## What pgrls does that CodeQL does not

- **Live-database introspection** — reads what's *enforced*, not what
  the application code intends. Catches policies an ORM applied that
  aren't in any source file.
- **Semantic RLS rule catalogue** — 43 rules tuned to the bug
  classes that ship past code review (SEC004 inverted auth, SEC027
  missing per-user scope, SEC030 nullable discriminator, SEC018
  role-as-discriminator, VIEW001–004 view-mediated bypasses, …).
- **Per-policy index health analysis** (PERF003/PERF004) — catches
  policies filtering on un-indexed or function-wrapped columns that
  defeat plain B-tree indexes.
- **Mechanical auto-fix** for 12 rules — emits SQL ready for the next
  migration.
- **Semantic policy-diff** (`pgrls diff`) — classifies migrations by
  access widening (SAFE / BREAKING / REQUIRES_REVIEW / DANGEROUS),
  not by raw DDL shape.
- **`pgrls.testing`** pytest plugin for RLS isolation tests.

## SARIF + Code Scanning: zero-friction coexistence

pgrls emits SARIF (`pgrls lint --format sarif`), which is exactly the
format Code Scanning ingests via `github/codeql-action/upload-sarif`.
Findings from both tools land in the same dashboard, scoped under
distinct "tool" labels in the SARIF runs array. A reviewer sees
*"CodeQL says you have an SQL injection here, pgrls says the policy
that's supposed to backstop it doesn't actually filter on `owner_id`"*
in the same PR — that's defence-in-depth as a workflow, not a
slideware claim.

## Could you write RLS queries in CodeQL?

Technically possible (CodeQL's query language is expressive) but
heavy:

- CodeQL builds a database from compiled artifacts; it doesn't have a
  natural "scan the running Postgres catalog" mode.
- The bugs pgrls catches require parsing `CREATE POLICY` predicates
  (a parser CodeQL doesn't ship for Postgres SQL) **and** consulting
  live schema metadata (column nullability, index leading-column,
  role grants) — which exists only in the database, not the source.
- pgrls's 43 rules already encode the catalogue; writing them again
  in CodeQL would be a multi-quarter project for the same outcome.

## Honest summary

For a team that already runs Code Scanning, adding pgrls is one
workflow step (`pgrls lint --format sarif | upload-sarif`) and gives
you a second tool surfacing in the same UI. The two operate on
different artifacts, so they never conflict; the SARIF combiner just
shows both runs side-by-side. *"Why not write RLS queries in
CodeQL?"* — because the source for RLS isn't application code; it's
the database catalog, and CodeQL doesn't ingest that.
