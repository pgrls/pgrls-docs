---
title: "vs squawk"
parent: Comparisons
nav_order: 20
permalink: /comparisons/squawk/
---

# pgrls vs. squawk — do I need both?

**Short answer: yes.** They run at adjacent stages of the same
pipeline and never look at the same artifact. squawk reads your
migration files *before* you apply them; pgrls reads the live
database *after* you do.

## The kind of bug each one catches

**squawk** ([github.com/sbdchd/squawk](https://github.com/sbdchd/squawk))
fires on migration hazards like this:

```sql
ALTER TABLE huge_table ADD COLUMN status TEXT NOT NULL DEFAULT 'ok';
-- ^ rewrites every row, holds AccessExclusiveLock,
--   blocks reads & writes for the duration.
```

That's the canonical migration-safety bug it's built to prevent.

**pgrls** fires on security bugs in the *result* of a migration —
the policies that ended up in the catalog after the SQL ran:

```sql
CREATE POLICY tenant_read ON public.documents
    FOR SELECT
    USING (auth.uid() IS NULL OR owner_id = auth.uid());
```

That policy applies cleanly (no lock issues, squawk would not
flag it) and admits every row to anonymous clients. pgrls flags
it as **SEC004**.

## Capability check

|                                       | squawk | pgrls |
| ------------------------------------- | :---:  | :---: |
| Catches lock-blocking DDL             | ✓      | —     |
| Catches RLS bypass / row-leak bugs    | —      | ✓     |
| Reads `.sql` migration files          | ✓      | —     |
| Reads live Postgres catalog           | —      | ✓     |
| Auto-fix                              | —      | ✓ (19 of 68 rules) |
| Postgres-version-aware                | ✓      | ✓ (PG15+)         |

## Wire both into CI

```yaml
- run: squawk migrations/*.sql        # pre-apply: refuse unsafe DDL
- run: psql … -f migrations/0001.sql  # apply to ephemeral Postgres
- run: pgrls lint --schemas public    # post-apply: audit the result
```

squawk only sees the migration text; pgrls only sees the resulting
state. They cannot collide.

## Verdict

Use both. squawk asks *"can I deploy this without taking the
database down?"* pgrls asks *"if I do deploy it, are the rows
actually safe?"* Both are CI questions, both deserve answers,
neither tool tries to do the other's job.
