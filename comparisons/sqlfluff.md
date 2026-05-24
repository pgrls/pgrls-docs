---
title: "vs sqlfluff"
parent: Comparisons
nav_order: 10
permalink: /comparisons/sqlfluff/
---

# pgrls vs. sqlfluff

**Different concerns. Coexistence, not competition.**

[sqlfluff](https://github.com/sqlfluff/sqlfluff) is a SQL **style and
formatting** linter. It covers spacing, indentation, capitalisation,
templating (Jinja, dbt), and ~25 SQL dialects. It is, in its own
words, "the SQL linter for humans." Auto-fix is its headline feature.

**pgrls** is a Row-Level Security policy linter for Postgres. It
introspects a live database, parses every RLS policy's `USING` and
`WITH CHECK` predicates, and flags semantic bugs (broken row scoping,
inverted auth checks, missing `WITH CHECK`, `BYPASSRLS` roles,
per-row auth-function evaluation, view-mediated RLS bypasses).

The two tools don't overlap.

## At a glance

|                          | sqlfluff                              | pgrls                                                 |
| ------------------------ | ------------------------------------- | ----------------------------------------------------- |
| Scope                    | SQL style / formatting                | Row-Level Security correctness                        |
| Input                    | `.sql` files                          | Live Postgres database (introspection)                |
| Dialect                  | 25+ (Postgres, BigQuery, Snowflake…) | Postgres only                                         |
| Surfaces RLS bugs?       | No                                    | Yes (43 rules across SEC / PERF / HYG / VIEW)         |
| Auto-fix                 | Most style rules                      | 12 of 43 rules                                        |
| CI integration           | Pre-commit, GH Actions, VS Code       | GitHub Action, pre-commit, every output format        |
| Detects `auth.uid() IS NULL OR …` | No                          | Yes (SEC004)                                          |

## What sqlfluff does that pgrls does not

- Multi-dialect SQL style/formatting across the whole SQL surface
  (SELECT, JOIN, window functions, …).
- Auto-formats existing SQL on save (VS Code integration).
- Works on raw `.sql` files — no database required.
- Handles dbt / Jinja templating.

## What pgrls does that sqlfluff does not

- Reads the *enforced* state of a running Postgres database (not just
  what's in a migration file). Catches policies an ORM or hot-fix
  applied that aren't in version control.
- Semantic analysis of `USING` / `WITH CHECK` predicate ASTs — flags
  bugs like `auth.uid() IS NULL OR …` (SEC004), missing per-user
  scoping (SEC027), nullable discriminators (SEC030), `current_user`
  as a tenant key (SEC018).
- Per-policy index health (PERF003 / PERF004): catches policies
  filtering on un-indexed or function-wrapped columns that defeat
  plain B-tree indexes.
- Semantic policy-diff (`pgrls diff`): classifies migrations
  SAFE / BREAKING / REQUIRES_REVIEW / DANGEROUS, so CI gates on access
  *widening*, not on schema churn.
- `pgrls.testing` pytest plugin for actual RLS isolation tests.

## Use them together

For a Postgres project with RLS, the cleanest CI stack runs both:
sqlfluff for SQL style (across migrations, application queries,
dbt models); pgrls for RLS correctness against the migrated database.
They consume different inputs and emit different findings, so the
output never collides.

## Honest summary

If someone in a Show HN thread asks *"why not just use sqlfluff?"* —
the answer is that sqlfluff doesn't read policies and isn't trying to.
It's a great formatter; pgrls is a security linter. The right answer
is *both*.
