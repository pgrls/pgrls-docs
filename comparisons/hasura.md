---
title: "+ Hasura"
parent: Comparisons
nav_order: 130
permalink: /comparisons/hasura/
---

# pgrls + Hasura — if I use Hasura, do I need pgrls?

**Depends.** Hasura permissions are *engine-level* — they're enforced
by the Hasura layer, not by Postgres RLS. So pgrls's answer splits
two ways:

- **Hasura-only setup, no direct DB access** → pgrls has nothing to
  audit. Hasura permissions live in metadata, not in Postgres; pgrls
  reads Postgres.
- **Hasura + RLS layered in for defence-in-depth** → pgrls is the
  audit layer for that RLS. This is the growing pattern for teams
  worried about non-Hasura DB access (BI tools, admin scripts,
  Lambda workers, compromised admin tokens).

## How Hasura and RLS differ

Hasura's docs are explicit: *"Hasura roles and permissions are
implemented at the Hasura Engine layer. They have no relationship
to database users and roles."*

That means:

```yaml
# Hasura metadata — enforced by Hasura, invisible to Postgres
- table: documents
  permissions:
    select:
      filter:
        owner_id: { _eq: X-Hasura-User-Id }
```

A direct `psql` connection bypasses this completely. The only thing
that constrains a non-Hasura caller is what Postgres itself enforces
— which is RLS, if you've enabled it.

## When pgrls is relevant

If you've layered RLS in *under* Hasura, this is the bug class pgrls
catches that nothing else does:

```sql
-- The defence-in-depth RLS policy you wrote on the same table:
CREATE POLICY tenant_read ON public.documents
    FOR SELECT
    USING (auth.uid() IS NULL OR owner_id = auth.uid());
```

If your Hasura permissions are correct but the RLS layer has this
bug, a direct DB connection sees every row — anonymous or
otherwise. Hasura's metadata-validation tools won't surface it (they
don't read Postgres policies). pgrls flags it as **SEC004**.

## Capability check

|                                          | Hasura | pgrls |
| ---------------------------------------- | :---:  | :---: |
| GraphQL API + permissions metadata       | ✓      | —     |
| Permissions enforced by Hasura engine    | ✓      | —     |
| Audits Postgres RLS policies             | —      | ✓     |
| Audits Hasura metadata permissions       | —      | —     |
| Useful for direct-DB-access scenarios    | —      | ✓     |

## Wire pgrls in (if you have RLS)

```yaml
- uses: pgrls/pgrls-action@v1
  with:
    database-url: ${{ secrets.HASURA_DB_URL }}
    schemas: public
```

## Verdict

- **Pure Hasura, no direct DB access?** Skip pgrls. Hasura's own
  metadata tooling is the audit layer.
- **RLS layered in for defence-in-depth?** pgrls is the audit tool.
- **Migrating off Hasura?** RLS becomes load-bearing; lint it before
  the cutover.
- **Analyst tools or admin scripts connect directly?** Then RLS is
  the only authorization that applies to them — pgrls audits whether
  it works.
