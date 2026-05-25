---
title: "+ Supabase"
parent: Comparisons
nav_order: 110
permalink: /comparisons/supabase/
---

# pgrls + Supabase — if I use Supabase, do I need pgrls?

**Short answer: yes, especially.** Supabase ships the RLS engine
(`auth.uid()`, `auth.role()`, `auth.jwt()`, the `anon` /
`authenticated` / `service_role` triad). It does not ship a linter
for the policies you write against that engine. pgrls is the
missing piece.

## The kind of bug pgrls catches that Supabase doesn't

Supabase docs warn about *some* of these and the rest fly under the
radar. The two that bite hardest in real-world Supabase codebases:

**(1) `IS NULL OR …` admits every row to anonymous clients.**

```sql
CREATE POLICY tenant_read ON public.documents
    FOR SELECT
    USING (auth.uid() IS NULL OR owner_id = auth.uid());
```

`auth.uid()` returns NULL for unauthenticated requests; the `IS
NULL` branch is true; the `OR` short-circuits; anonymous clients see
every row. The Supabase RLS docs explicitly recommend writing this
the other way (`IS NOT NULL AND … = auth.uid()`) — but nothing
checks that you did. pgrls flags it as **SEC004**.

**(2) `user_metadata` is end-user writable.**

```sql
USING (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin')
```

Any authenticated user calls
`supabase.auth.updateUser({ data: { role: 'admin' }})` from the
client SDK; the next JWT carries it; the policy reads it; the user
is admin. The safe counterpart is `app_metadata`
(service-role-only). pgrls flags this as **SEC033**.

## Capability check

|                                       | Supabase | pgrls |
| ------------------------------------- | :---:    | :---: |
| Hosted Postgres + auth + storage      | ✓        | —     |
| Provides the RLS engine               | ✓        | —     |
| Ships a CI linter for RLS policies    | —        | ✓     |
| Catches the `IS NULL OR …` footgun    | docs warn | flags & fails CI |
| Catches the `user_metadata` bypass    | —        | ✓     |
| Per-row perf trap (PERF001 wrap)      | docs recommend | flags every miss |
| Bug surfaces in CI vs in production   | production | CI |

## Wire pgrls into a Supabase project

`supabase start` runs a local Postgres; pgrls runs against it:

```yaml
- run: supabase start
- run: pgrls lint --database-url "$(supabase status -o env | grep DB_URL | cut -d= -f2)" --schemas public
```

Or the one-liner in GitHub Actions (uses your hosted DB URL from a
secret):

```yaml
- uses: pgrls/pgrls-action@v1
  with:
    database-url: ${{ secrets.SUPABASE_DB_URL }}
    schemas: public
```

## Verdict

Supabase ships the engine; pgrls ships the linter. Using both is the
default sane setup. Most Supabase RLS bugs that ship to production
fall into one of the rule classes pgrls already catches — see the
[Supabase recipe](https://github.com/pgrls/pgrls/blob/main/docs/recipes/supabase.md)
for the canonical CI wire-up.
