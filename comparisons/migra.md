---
title: "vs migra"
parent: Comparisons
nav_order: 70
permalink: /comparisons/migra/
---

# pgrls vs. migra — do I need both?

**Short answer: no.** migra was a schema-diff tool that was
deprecated in 2022 and never handled RLS policies in its output.
The only thing the two tools share is the word "diff" in a command
name. If you want migra's actual function (whole-schema migrations)
today, see [Atlas](atlas.md).

## What migra did, and what `pgrls diff` does

**migra** ([github.com/djrobstep/migra](https://github.com/djrobstep/migra))
diffed two Postgres schemas and emitted the SQL to migrate one into
the other:

```bash
migra postgres://old postgres://new
# → ALTER TABLE …, CREATE INDEX …, etc.
```

The README marks the project deprecated as of September 2022 and
points at a successor (`results`). At its peak it never touched RLS
policies in its diff output — it operated on tables, columns,
indexes, constraints, views.

**`pgrls diff`** is a different command in spirit. It diffs two
*policy* snapshots and classifies the change by what it does to
*row access*:

```bash
pgrls snapshot --output=before.json
# … apply your migration …
pgrls diff before.json
# → SAFE / BREAKING / REQUIRES_REVIEW / DANGEROUS
```

It does not emit migration SQL. It tells you whether a migration
*widened access* — orthogonal to whether the schema shape changed.

## Capability check

|                                  | migra (deprecated 2022) | `pgrls diff`                     |
| -------------------------------- | :---:                   | :---:                            |
| Whole-schema diff → migration SQL | ✓                       | —                                |
| Active maintenance               | —                       | ✓                                |
| Handles RLS policies             | —                       | ✓ (that's the whole point)        |
| Classifies access widening       | —                       | ✓ (SAFE/BREAKING/REVIEW/DANGEROUS) |

## Verdict

migra is gone; `pgrls diff` is unrelated. For migra's old role
(whole-schema diff + migration generation), use [Atlas](atlas.md).
Use `pgrls diff` *on top of* a real migration tool, as the access-
widening gate for the RLS policies the migration touched.
