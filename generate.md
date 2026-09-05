---
title: Generate — scaffold correct RLS
layout: default
nav_order: 3
permalink: /generate/
description: pgrls generate scaffolds gold-standard Postgres RLS — ENABLE, FORCE, an isolation policy, a restrictive floor and the index — and --strict-binding makes an unbound tenant fail loudly instead of returning an empty result.
---

# `pgrls generate` — scaffold RLS that lints clean

The rest of pgrls tells you what's wrong with the policies you have. `pgrls
generate` writes the ones you don't.

For every table carrying a discriminator column (`tenant_id` by default) that
has **no policies at all**, it emits the complete correct setup:

```bash
pgrls generate --database-url "$DATABASE_URL"
```

```sql
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents FORCE ROW LEVEL SECURITY;
CREATE POLICY documents_tenant_isolation ON public.documents TO authenticated
    USING      (tenant_id = (SELECT current_setting('app.tenant_id', true)::uuid))
    WITH CHECK (tenant_id = (SELECT current_setting('app.tenant_id', true)::uuid));
CREATE POLICY documents_tenant_floor ON public.documents AS RESTRICTIVE TO authenticated
    USING      (tenant_id = (SELECT current_setting('app.tenant_id', true)::uuid))
    WITH CHECK (tenant_id = (SELECT current_setting('app.tenant_id', true)::uuid));
CREATE INDEX IF NOT EXISTS pgrls_idx_288ae5d2c0a9f581 ON public.documents (tenant_id);
```

Five things, each of which is a rule someone usually forgets:

| statement | what it prevents |
|---|---|
| `ENABLE ROW LEVEL SECURITY` | SEC001 — policies that exist but never run |
| `FORCE ROW LEVEL SECURITY` | SEC002 — the table owner reading every row |
| the permissive policy | the actual tenant scoping |
| the `RESTRICTIVE` floor | a later permissive `OR` branch widening access |
| the index | PERF003 — a sequential scan on every policy check |

The `(SELECT …)` wrapper is deliberate: it makes Postgres evaluate the session
read **once per statement** as a cached InitPlan rather than once per candidate
row. That is the same rewrite PERF001 flags, so the generated policy lints
clean rather than tripping the linter that ships beside it.

The whole point is the round trip:

```bash
pgrls generate --apply && pgrls lint     # ...and lint finds nothing
```

**`generate` never touches a table that already has policies.** Hand-written
policy intent is never clobbered; those tables are reported as skipped, and you
refine them with `pgrls lint` and `pgrls fix` instead. Re-running after
applying is a no-op.

## Two scoping models

- **`--model tenant`** (default) — rows belong to a tenant, scoped on
  `tenant_id`.
- **`--model owner`** — rows belong to a user, scoped on `user_id`. With
  `--convention supabase` this emits the canonical
  `user_id = (SELECT auth.uid())` form.

The session value comes from `--convention`: `app-guc` reads
`current_setting('app.<col>', true)`, `postgrest` reads
`current_setting('request.jwt.claim.<claim>', true)`, and `supabase` compares
against `(SELECT auth.uid())`. A table whose column isn't the conventional one
takes an explicit override: `--table public.orgs:org_id`.

## `--strict-binding` — make a forgotten tenant fail loudly

Your isolation has two halves. pgrls proves the first — that the policies scope
rows correctly. The second is that your **application binds a tenant before it
queries**, and by default nothing checks it.

When it's missing, the failure is silent:

```sql
-- No tenant bound. current_setting(..., true) returns NULL,
-- tenant_id = NULL is NULL, the row is filtered.
SELECT * FROM documents WHERE id = $1;   -- 0 rows
```

Zero rows is **indistinguishable from "no such row"**. An application that
forgets to bind a tenant doesn't crash — it returns 404s, on every affected
path, starting the day its database role stops being the table owner. And a
test suite that connects as the owner cannot see it either: RLS isn't enforced
for that role, so a query that binds a tenant and one that doesn't are
identical to every test you have.

`--strict-binding` scaffolds the loud variant instead:

```bash
pgrls generate --strict-binding
```

```sql
CREATE OR REPLACE FUNCTION pgrls_require_tenant(setting_name text)
RETURNS text
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v text := current_setting(setting_name, true);
BEGIN
    IF v IS NULL OR v = '' THEN
        RAISE EXCEPTION
            'no tenant bound: % is not set on this connection',
            setting_name
            USING ERRCODE = 'insufficient_privilege',
                  HINT = 'Bind the tenant before querying (e.g. SET LOCAL), or use a connection helper that does.';
    END IF;
    RETURN v;
END
$$;

CREATE POLICY documents_tenant_isolation ON public.documents TO authenticated
    USING      (tenant_id = (SELECT pgrls_require_tenant('app.tenant_id')::uuid))
    WITH CHECK (tenant_id = (SELECT pgrls_require_tenant('app.tenant_id')::uuid));
```

The unbound query stops being an empty result and becomes an error pointing at
the call site that forgot:

```
ERROR:  no tenant bound: app.tenant_id is not set on this connection
HINT:   Bind the tenant before querying (e.g. SET LOCAL), or use a
        connection helper that does.
```

Run in dev and CI, that finds every instance on the first request — long before
a role change finds them in production. Set it once in `pgrls.toml` if you'd
rather not pass the flag:

```toml
[generate]
strict_binding = true
```

### When it fires, precisely

The helper call keeps the `(SELECT …)` wrapper, and that has a consequence
worth understanding rather than discovering.

Wrapped, the call is an InitPlan, evaluated when the scan produces a candidate
row to filter. So the raise fires **exactly when a row would have been returned
and was about to be wrongly hidden** — which is the case you care about. When
nothing matched anyway (an empty table, a token that genuinely doesn't exist)
it stays silent, and there the empty result was the truthful answer, so a
legitimate 404 is never converted into an error.

The unwrapped form raises in strictly more situations, including on an empty
table. It is not the default because it costs a function call **per row**:
measured on PostgreSQL 16, a 10,000-row scan calls the helper 10,001 times
unwrapped and once wrapped. PERF001 would flag it, too.

### Platform tables

Some tables are *meant* to be read before a tenant is chosen — `users`,
`memberships`, `operators`, anything consulted to work out which tenant the
request belongs to. Don't convert those. `generate` only ever targets tables
carrying the discriminator column, so platform tables are usually untouched
already; if one does carry it, allowlist the policy so [SEC055](#sec055) stays
quiet about it.

## SEC055 — keeping it converted
{: #sec055 }

Adopting the raising helper only protects you if **every** tenant policy uses
it. One policy left on the silent form is one code path that still 404s instead
of failing — and it's exactly the path nobody remembered to convert.

`pgrls lint` catches that drift. **SEC055** fires when a schema already uses a
raising binding helper somewhere and another policy still carries the silent
`current_setting(…, true)` form.

The trigger is the *schema*, not your config file — so it still reports when CI
lints a database without `pgrls.toml` beside it, which is exactly where drift
would otherwise go unnoticed. It also can't flood: a project that never adopted
the helper has no policy referencing one, so the rule stays silent entirely.

To exempt a table that's legitimately readable without a bound tenant:

```toml
[lint.rules.SEC055]
allowlist = ["public.users.p", "public.memberships.p"]
```

## Offline, without a database

`generate` works against raw DDL or a snapshot, so it fits a CI job with no
Postgres:

```bash
pgrls generate --sql-file schema.sql
pgrls generate --snapshot pgrls-snapshot.json
```

Offline output reflects only what's in the file — roles, grants and policies
defined elsewhere aren't visible — so review it against your full schema before
applying. Live introspection is the authoritative path.

## Output

Dry-run to stdout by default. `--output FILE` writes a migration-ready script,
and `--apply` executes the SQL in **one all-or-nothing transaction**.

```bash
pgrls generate --output migrations/0007_rls.sql
pgrls generate --apply
```
