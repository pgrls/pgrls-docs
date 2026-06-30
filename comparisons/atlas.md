---
title: "vs Atlas"
parent: Comparisons
nav_order: 30
permalink: /comparisons/atlas/
---

# pgrls vs. Atlas — do I need both?

**Short answer: yes, if you're using Atlas to manage RLS.** Atlas
*writes* and *applies* your policies as code. pgrls *audits* what
those policies do once applied. The roles are different layers of
the same workflow.

## The kind of bug each one catches

**Atlas** ([github.com/ariga/atlas](https://github.com/ariga/atlas))
fires on migration / schema hazards like this:

```sql
-- Atlas refuses to migrate this without manual ack:
DROP COLUMN owner_id;     -- destructive, possibly data-losing
```

It has 50+ analyzers covering destructive changes, lock-held
operations, drift detection — the migration-safety layer.

**pgrls** fires on a different class of bug. Even if Atlas applies
your policy cleanly, this still ships:

```sql
CREATE POLICY admins_only ON public.documents
    FOR ALL TO authenticated
    USING (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin');
```

`user_metadata` is end-user writable via Supabase's auth API
(`supabase.auth.updateUser({ data: { role: 'admin' }})`). Atlas
applied a policy that's *syntactically valid* but
*semantically self-bypassable*. pgrls flags it as **SEC033**.

## Capability check

|                                       | Atlas              | pgrls |
| ------------------------------------- | :---:              | :---: |
| Manages schema as code                | ✓                  | —     |
| Generates migrations                  | ✓                  | —     |
| 50+ DDL safety analyzers              | ✓                  | —     |
| Catches RLS bypass / semantic bugs    | —                  | ✓ (64 rules) |
| Auto-fix RLS findings                 | —                  | ✓ (20 of 64) |
| Multi-database                        | ✓ (PG/MySQL/MSSQL/…) | — (Postgres only) |

## Wire them together

The natural pipeline:

```
1. Atlas — writes RLS policies as declarative code, generates the migration.
2. CI applies the migration.
3. pgrls — reads the resulting catalog, audits the policies' semantics.
4. pgrls fix output (for 20 rule classes) → next Atlas migration.
```

Atlas guarantees the policy is applied as written. pgrls verifies
that what was written is actually correct.

## Verdict

Use both. Atlas asks *"is the schema in the database what we
declared?"* pgrls asks *"does the declared schema actually enforce
what we meant?"* No overlap on findings; full coverage when stacked.
