---
title: Home
layout: home
nav_order: 1
description: Public docs for pgrls — the Postgres Row-Level Security linter.
permalink: /
---

# pgrls

A **static analyzer for Postgres Row-Level Security**. Connects to a
live database, runs 67 rules over every policy, and flags the
semantic bugs (broken row scoping, inverted auth checks, missing
`WITH CHECK`, `BYPASSRLS` roles, view-mediated bypasses) that eyeball
review misses. For the costliest footgun — a policy that leaks every
row to anonymous users — pgrls goes past pattern-matching and runs the
**Z3 SMT solver** to *prove* the leak (SEC038). 19 of the 67 rules
mechanically auto-fix. MIT,
Python 3.11+, tested PostgreSQL 15–17.

```bash
pip install pgrls
export DATABASE_URL='postgres://…'
pgrls lint
```

## A Supabase footgun pgrls catches — SEC033

A Supabase RLS policy that gates on `user_metadata` is
**self-bypassable** in one line of client code:

```sql
USING (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin')
-- exploit: await supabase.auth.updateUser({ data: { role: "admin" } })
```

`user_metadata` is end-user writable via the standard Supabase auth
API — by design. The safe counterpart is `app_metadata`
(service-role-only). `pgrls lint --rule SEC033` catches every shape
(all four JSON operators + `raw_user_meta_data` column refs). Default
severity `error` — fails CI on first sight. Released 2026-05-24.

## Quick links

- **[Quickstart](https://github.com/pgrls/pgrls/blob/main/docs/QUICKSTART.md)** —
  5 minutes from `pip install` to a real RLS finding.
- **[Rule reference (AGENTS.md)](https://github.com/pgrls/pgrls/blob/main/AGENTS.md)** —
  all 67 rules, each with detection logic, severity, and remediation.
- **[GitHub Action on the Marketplace](https://github.com/marketplace/actions/pgrls-postgres-rls-linter)** —
  one-line CI integration.
- **[CHANGELOG](https://github.com/pgrls/pgrls/blob/main/CHANGELOG.md)**.

## On this site

- **[Verify — the prover](verify/)** — `pgrls verify` proves tenant isolation
  with Z3 (reads *and* writes) and confirms the proof against your live database.
- **[Comparisons](comparisons/)** — pgrls vs adjacent tools and how it
  fits with Postgres ecosystems (Supabase, PostgREST, Hasura, Django).

## The other bug pgrls catches (the classic)

```sql
CREATE POLICY tenant_read ON public.documents
    FOR SELECT
    USING (auth.uid() IS NULL OR owner_id = auth.uid());
```

Reads correct in English; ships past code review; admits **every row**
to unauthenticated clients because `auth.uid()` returns NULL for any
session without a JWT, the `IS NULL` branch is true, the `OR`
short-circuits. pgrls flags it as **SEC004** in milliseconds — and
catches the *disguised* variants (a `NOT (… IS NOT NULL)` inversion, a
`COALESCE` wrapper) as **SEC038**, which runs the Z3 SMT solver to
**prove** the policy is unconditionally true for an anonymous session —
semantic detection no regex can match. 59 other rules cover the rest of
the RLS bug space.
