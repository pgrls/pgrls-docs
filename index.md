---
title: Home
layout: home
nav_order: 1
description: Public docs for pgrls — the Postgres Row-Level Security linter.
permalink: /
---

# pgrls

A **static analyzer for Postgres Row-Level Security**. Connects to a
live database, runs 43 rules over every policy, and flags the
semantic bugs (broken row scoping, inverted auth checks, missing
`WITH CHECK`, `BYPASSRLS` roles, view-mediated bypasses) that eyeball
review misses. 12 of the 43 rules mechanically auto-fix. MIT,
Python 3.11+, tested PostgreSQL 15–17.

```bash
pip install pgrls
export DATABASE_URL='postgres://…'
pgrls lint
```

## Quick links

- **[Quickstart](https://github.com/pgrls/pgrls/blob/main/docs/QUICKSTART.md)** —
  5 minutes from `pip install` to a real RLS finding.
- **[Rule reference (AGENTS.md)](https://github.com/pgrls/pgrls/blob/main/AGENTS.md)** —
  all 43 rules, each with detection logic, severity, and remediation.
- **[GitHub Action on the Marketplace](https://github.com/marketplace/actions/pgrls-postgres-rls-linter)** —
  one-line CI integration.
- **[CHANGELOG](https://github.com/pgrls/pgrls/blob/main/CHANGELOG.md)**.

## On this site

- **[Comparisons](comparisons/)** — pgrls vs adjacent tools and how it
  fits with Postgres ecosystems (Supabase, PostgREST, Hasura, Django).

## The bug pgrls catches

```sql
CREATE POLICY tenant_read ON public.documents
    FOR SELECT
    USING (auth.uid() IS NULL OR owner_id = auth.uid());
```

Reads correct in English; ships past code review; admits **every row**
to unauthenticated clients because `auth.uid()` returns NULL for any
session without a JWT, the `IS NULL` branch is true, the `OR`
short-circuits. pgrls flags it as **SEC004** in milliseconds. 42 other
rules cover the rest of the RLS bug space.
