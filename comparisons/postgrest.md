---
title: "+ PostgREST"
parent: Comparisons
nav_order: 120
permalink: /comparisons/postgrest/
---

# pgrls + PostgREST — if I use PostgREST, do I need pgrls?

**Short answer: yes.** PostgREST's design is uncompromising —
*"all authorization happens in the database."* That puts the entire
weight of authorization correctness on your RLS policies being
right. PostgREST ships no linter for them. pgrls is that linter.

## The kind of bug pgrls catches in PostgREST setups

Three patterns recur across PostgREST projects in the wild:

**(1) Anonymous-client bypass via missing JWT claim.**

```sql
USING (current_setting('request.jwt.claims', true) IS NULL
       OR owner_id::text = current_setting('request.jwt.claim.sub'))
```

The GUC is NULL when no `Bearer` header is sent — the `IS NULL`
disjunct is true, every row visible to anonymous clients. pgrls
flags this as **SEC004** (the default auth-function set includes
`current_setting`).

**(2) `current_user` as a tenant key.**

```sql
USING (owner_role = current_user)
```

PostgREST uses a small pool of Postgres roles (typically just
`authenticated`); every signed-in user has the same `current_user`.
The policy collapses across users — everyone sees everyone else's
rows. pgrls flags this as **SEC018**.

**(3) Nullable discriminator silently flips polarity.**

```sql
USING (tenant_id = current_setting('request.jwt.claim.tenant_id', true)::uuid)
```

A row whose `tenant_id` is NULL is invisible today (NULL = value
evaluates NULL). The moment any policy on the table uses a
NULL-tolerant form (`IS NOT DISTINCT FROM`, `COALESCE(…)`,
`tenant_id IS NULL OR …`), those rows become visible to *every*
tenant at once. pgrls flags the nullable discriminator as **SEC030**
*before* the second policy ships.

## The `db-pre-request` gotcha

PostgREST's `db-pre-request` SQL function runs before every request,
typically to populate GUCs from the JWT. If it silently fails (a
swallowed exception, a misconfigured claim), the GUCs are unset and
the same `current_setting(...) = …` predicate flips behavior. Both
shapes pgrls catches — SEC004 for the IS-NULL-OR pattern, SEC030 for
the nullable-discriminator interaction — cover this failure mode.

## Capability check

|                                     | PostgREST | pgrls |
| ----------------------------------- | :---:     | :---: |
| HTTP-to-Postgres bridge             | ✓         | —     |
| Sets `request.jwt.claims` GUCs      | ✓         | —     |
| Audits the RLS policies it relies on | —        | ✓     |
| Catches the anonymous-bypass shape  | —         | ✓     |
| Catches `current_user`-as-tenant    | —         | ✓     |
| Bug surfaces in CI vs in production | first failing request | CI |

## Wire pgrls into a PostgREST project

```yaml
- run: psql … -f schema.sql           # apply your migrations
- run: pgrls lint --schemas public    # audit the resulting RLS
```

Or via the GitHub Action:

```yaml
- uses: pgrls/pgrls-action@v1
  with:
    database-url: ${{ secrets.POSTGREST_DB_URL }}
    schemas: public
```

## Verdict

PostgREST's design assumes the database's authorization is correct.
pgrls is how you verify that assumption. The
[PostgREST recipe](https://github.com/pgrls/pgrls/blob/main/docs/recipes/postgrest.md)
walks through the worked CI wire-up plus the `db-pre-request` gotcha.
