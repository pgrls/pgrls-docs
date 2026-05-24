---
title: "vs squawk"
parent: Comparisons
nav_order: 20
permalink: /comparisons/squawk/
---

# pgrls vs. squawk

**Adjacent concerns. Coexistence, not competition.**

[squawk](https://github.com/sbdchd/squawk) is a Postgres **migration
safety** linter. It analyses DDL statements for lock-heavy operations,
zero-downtime hazards, and schema-evolution traps —
`require-concurrent-index-creation`, `prefer-bigint-over-int`,
`disallowed-unique-constraint`, and ~30 similar rules. The headline
promise is *"prevent unexpected downtime caused by database
migrations."*

**pgrls** is a Postgres **Row-Level Security** linter. It runs against
a live database and analyses the semantics of every RLS policy
(`USING` / `WITH CHECK` predicates, role grants, view-mediated
bypasses, fix-or-allowlist remediation).

The two live in the same conceptual neighbourhood — *Postgres-aware
CI linters* — but ask different questions about the same database.
They're complementary.

## At a glance

|                       | squawk                                            | pgrls                                                |
| --------------------- | ------------------------------------------------- | ---------------------------------------------------- |
| Question it asks      | "Is this DDL safe to roll out?"                   | "Are the RLS policies correct?"                      |
| Input                 | Migration / DDL `.sql` files                      | Live Postgres database (introspection)               |
| What it flags         | Lock contention, unsafe ALTERs, type-overflow     | Row-scoping bugs, inverted auth, missing WITH CHECK  |
| Database              | Postgres-specific                                 | Postgres-specific                                    |
| Auto-fix              | No (advisory)                                     | 12 of 43 rules                                       |
| Surfaces RLS bugs?    | No                                                | Yes (43 rules)                                       |
| Surfaces DDL hazards? | Yes (~30 rules)                                   | No                                                   |
| CI integration        | GitHub Action, pre-commit, VS Code, PR comments   | GitHub Action, pre-commit, every output format       |

## What squawk does that pgrls does not

- Static analysis of `ALTER TABLE` / `CREATE INDEX` / `CREATE
  CONSTRAINT` statements — flags long-held locks and write-blocking
  operations before they hit production.
- Operates on `.sql` files; no database connection needed.
- Postgres-version-aware (`--pg-version`) so rules account for
  what's safe on the target version.
- Posts PR comments via its `upload-to-github` subcommand.

## What pgrls does that squawk does not

- Reads the *enforced* state of a running Postgres database, including
  policies the migration files don't fully describe (column nullability,
  triggers, view dependencies, role grants).
- AST-level analysis of every RLS policy's `USING` / `WITH CHECK`
  predicate — catches the bugs that ship past code review:
  `auth.uid() IS NULL OR …` (SEC004), per-user-scoping gaps inside a
  tenant (SEC027), nullable discriminators (SEC030), `current_user`
  used as a tenant key (SEC018), `BYPASSRLS` roles (SEC005), view-mediated
  RLS bypasses (VIEW001–004).
- Semantic policy-diff (`pgrls diff`): classifies a migration
  SAFE / BREAKING / REQUIRES_REVIEW / DANGEROUS by *access widening*,
  not just by raw DDL shape.
- `pgrls.testing` pytest plugin for RLS isolation tests.
- Mechanical auto-fix for 12 of the 43 rules.

## Use them together

For a Postgres project shipping migrations, the CI stack we'd run:

1. **squawk** against the migration files — *"will this ALTER lock the
   table?"* Stops the unsafe DDL before it reaches a database.
2. Apply migrations to a CI Postgres.
3. **pgrls** against the migrated database — *"do the policies that
   resulted actually enforce what we meant?"*

No finding ever collides — squawk only sees the migration text, pgrls
only sees the resulting state.

## Honest summary

squawk asks *"can I deploy this without taking the database down?"*
pgrls asks *"if I do deploy it, are the rows actually safe?"* Both
are CI questions, both deserve answers, and neither tool tries to
answer the other's question.
