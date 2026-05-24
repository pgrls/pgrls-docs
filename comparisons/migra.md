---
title: "vs migra"
parent: Comparisons
nav_order: 70
permalink: /comparisons/migra/
---

# pgrls vs. migra

**Adjacent concerns. migra has been deprecated; pgrls overlaps only
narrowly with what migra did.**

[migra](https://github.com/djrobstep/migra) was a Postgres schema-diff
tool — point it at two databases, get back the SQL that migrates one
into the other. The project was **deprecated in September 2022** with
no further releases planned (the README points at a successor project,
`results`). At its peak it was the popular Python answer to "diff two
Postgres schemas and emit a migration."

**pgrls** is a Row-Level Security linter for Postgres. It does include
a `pgrls diff` command, which diffs two policy snapshots (or a snapshot
vs. a live DB) — but `pgrls diff` is a **semantic policy-change
classifier**, not a general DDL migration generator. The two tools'
diff features overlap in *name only*.

## At a glance

|                                  | migra (deprecated 2022)                       | pgrls                                                 |
| -------------------------------- | --------------------------------------------- | ----------------------------------------------------- |
| Status                           | Deprecated; no further releases               | Actively maintained (current 0.6.x)                   |
| Scope                            | Whole-schema diff → migration SQL             | RLS linter + RLS-policy semantic diff                 |
| Database                         | Postgres                                      | Postgres                                              |
| Handles RLS policies in the diff | No — schema-shape diff only                   | Yes — that IS the focus                               |
| Emits migration SQL              | Yes (full schema migration)                   | No (pgrls is read-only; auto-fix emits remediation SQL but doesn't manage migrations) |
| Classification of changes        | None — emits raw DDL                          | SAFE / BREAKING / REQUIRES_REVIEW / DANGEROUS         |
| Linter rules                     | None                                          | 43                                                    |

## Where their diff features overlap (narrowly)

Both can show *"what changed between two Postgres database states."*
migra did this for the whole schema (tables, columns, indexes,
constraints, views) and emitted migration SQL. **migra never explicitly
handled RLS policies in its diff output.**

pgrls's `pgrls diff` does only the RLS-policy delta — but it
classifies the change by *what it does to row access*:

- **SAFE** — predicate tightened, no new role grant, no new
  permissive policy.
- **BREAKING** — predicate widened OR a new permissive policy grants
  access where none existed before.
- **REQUIRES_REVIEW** — semantically ambiguous (e.g. an OR-branch
  added that may or may not widen, depending on data).
- **DANGEROUS** — a class of regressions that almost always means a
  leak (e.g. an `IS NULL OR …` disjunct added, a `BYPASSRLS` role
  newly granted).

That classification is the whole value — it gates CI on access
*widening*, not on every schema change.

## If you used migra in the past

You probably used it for whole-schema migrations; pgrls doesn't try to
fill that role. For schema migrations specifically, the modern
alternatives are:

- **[Atlas](atlas.md)** — declarative + versioned schema management,
  multi-database, with 50+ DDL safety analyzers.
- **migra's listed successor** (`results`) — if it has matured into
  the role.
- Framework-native migration tooling (Django, Rails, sqitch, Flyway,
  golang-migrate, etc.).

pgrls slots in as the **policy-correctness layer** on top of whichever
migration tool you use — read the migrated state and tell you if the
RLS posture is actually safe.

## Honest summary

migra and pgrls don't really compete — migra solved a different
problem (whole-schema diffs / migration generation) and is no longer
maintained. The only overlap is the word "diff" in both tool names;
the semantics are completely different. If you want migra's actual
functionality today, [Atlas](atlas.md) is the modern answer; pgrls
sits beside it as the RLS-correctness check.
