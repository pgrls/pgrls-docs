---
title: Comparisons
nav_order: 2
has_children: true
permalink: /comparisons/
---

# Comparisons

Honest, fact-grounded comparisons of pgrls with every adjacent tool
or ecosystem. Each page covers what the other project does, what
pgrls does that it doesn't, what it does that pgrls doesn't, and how
they coexist. No FUD, no overclaiming.

## Direct-tool comparisons

Tools that share some space with pgrls in some way:

- **[vs sqlfluff](sqlfluff)** — SQL **style/formatting** linter, 25+ dialects, no RLS rules. Different concerns; coexist.
- **[vs squawk](squawk)** — Postgres **DDL migration safety** linter (lock contention, zero-downtime hazards), no RLS rules. Adjacent in CI; coexist.
- **[vs Atlas](atlas)** — declarative database **schema management** + 50+ DDL safety analyzers; explicitly supports managing RLS policies as code but has no out-of-the-box RLS semantic linting. Strongly complementary.
- **[vs Semgrep](semgrep)** — generic semantic SAST (30+ languages), no built-in RLS rules. Application-code layer vs pgrls's database layer.
- **[vs CodeQL](codeql)** — GitHub's query-based SAST, no RLS queries in the standard library. SARIF + Code Scanning UI lets pgrls findings render right next to CodeQL's.
- **[vs Snyk Code](snyk-code)** — commercial dev-focused SAST, no RLS coverage documented. Application-layer; coexist.
- **[vs migra](migra)** — Postgres whole-schema diff tool, deprecated 2022, never handled RLS in its diff. Different concept from `pgrls diff`.

## Ecosystem positioning

The major Postgres-RLS-using frameworks:

- **[+ Supabase](supabase)** — provides the RLS engine (`auth.uid()` / `auth.role()` / `auth.jwt()`, the role triad), no linter for the policies you write. pgrls is built for this pattern.
- **[+ PostgREST](postgrest)** — "all authorization happens in the database" by design; no built-in linter. pgrls audits the policies that decision rests on.
- **[+ Hasura](hasura)** — engine-level permissions in metadata, separate from RLS. pgrls is relevant when RLS is layered on top as defense-in-depth.
