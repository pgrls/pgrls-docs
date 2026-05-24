---
title: "vs Semgrep"
parent: Comparisons
nav_order: 40
permalink: /comparisons/semgrep/
---

# pgrls vs. Semgrep

**Different abstraction levels. Theoretically composable.**

[Semgrep](https://github.com/semgrep/semgrep) is a **language-agnostic
semantic SAST** that pattern-matches against source code in 30+
languages (Python, JS, Java, Go, Ruby, C/C++, Rust, …) and configuration
formats (YAML, JSON, Terraform, Dockerfile). The pattern DSL "looks like
the source code you're matching." Out of the box, the standard rule
registry targets *application-code* vulnerabilities (SQL injection,
auth-bypass, hardcoded secrets, etc.); Semgrep ships **no built-in rules
for Postgres Row-Level Security policies.**

**pgrls** is a Postgres-specific Row-Level Security linter. It
introspects a *live database* and reasons about every RLS policy's
`USING` / `WITH CHECK` AST — work Semgrep cannot do because the
artifact pgrls examines (the running database catalog) isn't source
code to begin with.

## At a glance

|                           | Semgrep                                                 | pgrls                                                  |
| ------------------------- | ------------------------------------------------------- | ------------------------------------------------------ |
| What it scans             | Source files in 30+ languages                           | Live Postgres database (catalog introspection)         |
| Where the bug is found    | Application code (the caller of the database)          | The database itself (the policy that enforces access)  |
| Surfaces RLS bugs?        | No built-in rules; theoretically writable as customs    | Yes — 43 rules tuned to RLS                            |
| SQL-aware                 | Pattern-matches SQL inside strings (limited)            | Full SQL/policy AST (via pglast)                       |
| Auto-fix                  | Yes for many built-in rules                             | 12 of 43 rules                                         |
| CI integration            | GitHub Action, GitLab, CircleCI, …                      | GitHub Action, pre-commit, every output format         |
| Custom rules              | Pattern DSL                                             | Python rule modules (with the rule-authoring guide)    |

## What Semgrep does that pgrls does not

- **Application-layer security analysis** across the whole code
  surface — SQL injection in the calling code, hardcoded credentials,
  taint analysis, dangerous deserialization, etc.
- **Polyglot** — works the same against Python, Java, Go, JS, etc.
- **Catches bugs in the code that calls the database** (e.g., a Django
  view that constructs raw SQL with string concatenation) — orthogonal
  to whether the database's RLS policies are correct.
- **Rule registry of thousands of community + Semgrep-maintained rules.**

## What pgrls does that Semgrep does not

- **Introspects a live database** — sees the enforced policy state,
  not the migration text. Catches policies a migration applied that
  aren't in version control (or vice versa).
- **AST-level semantic analysis of RLS policies** — detects
  `auth.uid() IS NULL OR …` (SEC004), missing per-user scoping
  (SEC027), nullable discriminators (SEC030), `current_user` as a
  tenant key (SEC018), `BYPASSRLS` roles (SEC005), view-mediated
  RLS bypasses (VIEW001–004), per-row auth-function evaluation
  (PERF001), and 35 more.
- **Mechanical auto-fix** for 12 rules that emit
  `CREATE POLICY` / `DROP POLICY` / `CREATE INDEX` SQL.
- **Semantic policy-diff** (`pgrls diff`) that classifies migrations
  SAFE / BREAKING / REQUIRES_REVIEW / DANGEROUS — by access widening.
- **`pgrls.testing`** pytest plugin for RLS isolation tests.

## Could you write RLS rules in Semgrep instead?

In principle — Semgrep's rule DSL is expressive enough to pattern-match
SQL literals in source code. In practice it doesn't work for RLS:

1. **The artifact is wrong.** RLS policies are typically authored in
   `CREATE POLICY` DDL inside migration files (or, on Supabase, via
   the dashboard with no source file at all). Semgrep can match the
   `CREATE POLICY` *literal* but can't reason about the predicate
   semantics — it sees opaque SQL strings, not the parsed policy AST.
2. **The check Semgrep would do is structural.** The bugs pgrls
   catches require semantic analysis: "is `auth.uid()` on the left of
   an `IS NULL OR …` disjunct at the top level of this `USING`
   clause?" That's a tree walk over the parsed `A_Expr` nodes —
   exactly what pgrls does (via `pglast`) and Semgrep doesn't.
3. **You can't catch what isn't there.** Semgrep operates on source;
   it cannot tell you a policy is *missing* a per-user predicate
   (SEC027), or that a discriminator column is *nullable* (SEC030) —
   both require schema metadata Semgrep doesn't have.

## Use them together

The natural composition: Semgrep on application code (caller-side SQL
hygiene, auth-bypass patterns), pgrls on the database (policy
correctness). Their findings never collide because they look at
disjoint artifacts.

## Honest summary

If a team is already running Semgrep as part of their SAST stack,
pgrls slots in next to it without overlap. *"Why not just write RLS
rules in Semgrep?"* — because the rules require parsed policy ASTs
plus live schema metadata (column nullability, indexes, role
membership), and Semgrep operates on source text.
