---
title: "vs sqlfluff"
parent: Comparisons
nav_order: 10
permalink: /comparisons/sqlfluff/
---

# pgrls vs. sqlfluff — do I need both?

**Short answer: yes.** sqlfluff catches *style* problems in SQL
text. pgrls catches *security* problems in your live database's
Row-Level Security policies. They never look at the same thing and
never flag the same finding.

## The kind of bug each one catches

**sqlfluff** ([github.com/sqlfluff/sqlfluff](https://github.com/sqlfluff/sqlfluff))
fires on style drift like this:

```sql
SELECT id,name from users where id=1
--           ^                  ^
--  missing space          inconsistent capitalization
```

It also covers indentation, templating (Jinja, dbt), and ~25 SQL
dialects. Auto-fix is its headline feature.

**pgrls** fires on security bugs like this:

```sql
CREATE POLICY tenant_read ON public.documents
    FOR SELECT
    USING (auth.uid() IS NULL OR owner_id = auth.uid());
```

That policy admits every row to anonymous clients
(`auth.uid()` returns `NULL`, the `IS NULL` branch is true, the
`OR` short-circuits). sqlfluff parses it fine; the column names,
quoting, and spacing are all correct. The bug is *semantic*. pgrls
flags it as **SEC004** in milliseconds.

## Capability check

|                                   | sqlfluff | pgrls |
| --------------------------------- | :---:    | :---: |
| SQL style / formatting            | ✓        | —     |
| Catches RLS bypass bugs           | —        | ✓     |
| Catches per-row perf traps in RLS | —        | ✓     |
| Reads from `.sql` files           | ✓        | —     |
| Reads from a live Postgres        | —        | ✓     |
| Auto-fix                          | ✓        | ✓ (17 of 51 rules) |
| Multi-dialect                     | ✓ (25+)  | — (Postgres only) |

## Wire both into CI

```yaml
- run: pip install sqlfluff pgrls
- run: sqlfluff lint .          # style on the .sql files
- run: psql … -f schema.sql     # apply to a CI Postgres
- run: pgrls lint --schemas public   # security on the result
```

Zero output collision: sqlfluff reads text, pgrls reads catalog.
Two distinct stages of the same pipeline.

## Verdict

Use both. The 30-second setup above gives you SQL style + RLS
security in the same CI job. Neither tool can do the other's job.
