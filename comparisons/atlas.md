---
title: "vs Atlas"
parent: Comparisons
nav_order: 30
permalink: /comparisons/atlas/
---

# pgrls vs. Atlas

**Different layers of the same stack. Strongly complementary.**

[Atlas](https://github.com/ariga/atlas) (Ariga) is a declarative
database-schema-management tool — schema-as-code, automated migration
generation, 50+ safety analyzers for DDL, and notably **explicit
support for managing row-level security policies as version-controlled
code** alongside roles and permissions.

**pgrls** is a Row-Level Security policy **linter** for Postgres. It
introspects a live database and flags semantic bugs in the *enforced*
policies (broken row scoping, inverted auth, missing `WITH CHECK`,
`BYPASSRLS` roles, view-mediated bypasses).

The relationship is not "vs" so much as "and." Atlas *writes* and
*migrates* RLS policies; pgrls *audits* them. The right CI stack for
a Postgres team running RLS uses both.

## At a glance

|                                | Atlas                                                            | pgrls                                                  |
| ------------------------------ | ---------------------------------------------------------------- | ------------------------------------------------------ |
| Primary function               | Schema management (declarative + versioned migrations)           | RLS policy linter                                      |
| Defines policies?              | Yes (RLS policies as code, alongside roles + permissions)        | No (it audits what's already there)                    |
| Migrates policies?             | Yes (declarative apply / versioned migrations)                   | No                                                     |
| Lints policy *semantics*?      | Custom rules possible; no out-of-the-box RLS-semantic catalogue  | Yes — 43 rules tuned to RLS specifically               |
| Database support               | Postgres, MySQL, MSSQL, SQLite, Oracle, Snowflake, ClickHouse, … | Postgres only                                          |
| Safety analyzers               | 50+ DDL/migration analyzers (destructive change, locks, drift)   | 43 RLS-correctness rules + 12 auto-fixers              |
| Semantic policy-diff?          | Migration-level diff (declarative ↔ database)                    | Semantic *access-widening* classifier (SAFE / BREAKING / REQUIRES_REVIEW / DANGEROUS) |
| CI integration                 | GH Actions, GitLab, CircleCI, Bitbucket, Azure, Kubernetes Op., Terraform | GitHub Action, pre-commit, every output format         |
| Auto-fix RLS bugs?             | No (Atlas generates the *intended* policy; it doesn't catch bugs in the intent) | Yes for 12 of 43 rules |

## What Atlas does that pgrls does not

- **Manages the full database schema** (tables, columns, indexes,
  constraints, views, triggers, AND RLS policies + roles + permissions)
  as version-controlled code. pgrls only reads; it doesn't manage or
  migrate.
- **Generates migrations** automatically from a declarative target
  state (HCL/SQL).
- **50+ DDL safety analyzers** for destructive changes, table locks,
  backward incompatibility, drift detection — the migration-safety
  layer (overlap with squawk on that axis).
- **Multi-database**: works the same against Postgres, MySQL, MSSQL,
  Oracle, Snowflake, and more.
- **Schema-as-code workflows** (Terraform provider, Kubernetes
  Operator, ArgoCD support) for teams that treat the database the
  way they treat infrastructure.
- **Drift detection** between declared and actual schema.

## What pgrls does that Atlas does not

- **RLS-specific bug catalogue**: 43 rules targeting the semantic
  bugs that ship past code review even when the policy "looks
  correct." Atlas validates that a policy *exists as declared*; pgrls
  validates that it *enforces what you meant*. The two are distinct:
  - `auth.uid() IS NULL OR owner = auth.uid()` is a valid CREATE
    POLICY (Atlas applies it cleanly) AND silently leaks every row
    to anonymous clients (pgrls flags it as SEC004).
  - A policy that scopes by `tenant_id` but not by `owner_id` is a
    syntactically clean Atlas declaration that leaks per-user data
    inside a tenant (pgrls flags it as SEC027).
- **Mechanical fixers** for 12 rules — emit `DROP POLICY`,
  `ALTER POLICY`, `CREATE INDEX` SQL ready to feed into the next
  migration (which Atlas, in turn, can then apply).
- **Semantic policy-diff** that asks specifically *"did access
  widen?"* — orthogonal to Atlas's structural drift detection.
- **`pgrls.testing`** pytest plugin for actual RLS isolation tests
  (role switching, per-test transactions, tenant-isolation assertions)
  — runtime verification that the deployed policies do what their
  declaration claims.

## Use them together

The natural pipeline:

1. **Atlas** owns the schema (incl. RLS policies + roles) as
   declarative code, generates migrations, runs its DDL safety
   analyzers.
2. **pgrls** runs against the migrated database (or, during
   development, against an `atlas schema apply --dry-run` preview)
   and audits the *semantics* of the policies Atlas just applied.
3. The 12 auto-fixable pgrls rules emit SQL that goes back into
   Atlas as the next migration.

No tool replaces the other — they sit at different layers. Atlas
asks *"is the schema what we declared?"* pgrls asks *"does the
declared schema actually enforce what we meant?"*

## Honest summary

If a Postgres team picks Atlas to manage its RLS policies, that's a
good fit and pgrls makes it better — Atlas guarantees the policies
are applied as written, pgrls audits whether they're written
correctly. The combination is stronger than either alone. The only
"vs" framing that holds up is *RLS-specific lint catalogue*: Atlas
has 50+ general migration analyzers but no out-of-the-box RLS-semantic
rules; pgrls has 43 rules tuned exclusively to RLS correctness.
