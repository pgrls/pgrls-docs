---
title: Comparisons
nav_order: 2
has_children: true
permalink: /comparisons/
---

# pgrls compared to adjacent tools

If you arrived here from a search like "pgrls vs X," the page you
want is linked below. Each one answers the same three questions:

1. **Do I need both, one, or neither?**
2. **What concrete bug does pgrls catch that the other tool doesn't?**
3. **Is there a 60-second way to wire pgrls into a setup that
   already has the other tool?**

## SQL / migration linters

- [**pgrls vs sqlfluff**](sqlfluff/) — style vs security; use both.
- [**pgrls vs squawk**](squawk/) — migration lock safety vs RLS
  correctness; use both, squawk pre-apply, pgrls post-apply.
- [**pgrls vs Atlas**](atlas/) — schema management vs policy linter;
  Atlas writes the policies, pgrls audits them.
- [**pgrls vs migra**](migra/) — migra was a schema-diff tool
  (deprecated 2022); `pgrls diff` is unrelated.

## Generic SAST

- [**pgrls vs Semgrep**](semgrep/) — Semgrep scans source; pgrls
  scans the live database. No overlap.
- [**pgrls vs CodeQL**](codeql/) — same story, but the SARIF
  output lands in the same Code Scanning UI.
- [**pgrls vs Snyk Code**](snyk-code/) — commercial SAST; no RLS
  coverage. Use both.

## Postgres RLS ecosystems

- [**pgrls + Supabase**](supabase/) — Supabase ships the RLS
  engine; pgrls is the linter that ecosystem doesn't ship.
- [**pgrls + PostgREST**](postgrest/) — PostgREST's design rests
  on RLS being correct. pgrls is how you verify that assumption.
- [**pgrls + Hasura**](hasura/) — Hasura permissions are separate
  from RLS. pgrls is relevant when you've layered RLS in for
  defence-in-depth.

## Not here

- **pgaudit** — audit logging, not linting. Different category.
- **ORMs** (Prisma, SQLAlchemy, Django, TypeORM) — construct
  queries; don't lint policies.
- **DB observability** (pgwatch, Datadog) — different category.
