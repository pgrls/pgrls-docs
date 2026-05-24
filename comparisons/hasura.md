---
title: "+ Hasura"
parent: Comparisons
nav_order: 130
permalink: /comparisons/hasura/
---

# pgrls vs. Hasura

**Different layers. Hasura permissions are not RLS — pgrls only sees
the RLS half.**

[Hasura](https://hasura.io) is a GraphQL API server over Postgres
(and other databases). Its authorization model is **engine-level,
not database-level**: roles, permissions, and row filters are declared
in Hasura's metadata, and the Hasura Engine enforces them when
translating a GraphQL query into SQL. The official docs are explicit:
*"Hasura roles and permissions are implemented at the Hasura Engine
layer. They have no relationship to database users and roles."*

**pgrls** is a Postgres Row-Level Security linter. It reads the
database catalog and audits the policies Postgres itself will
enforce. It cannot see Hasura's metadata-driven permission rules —
those live in Hasura, not Postgres.

So the two are at different layers. The question becomes: *do you
have RLS at all under a Hasura deployment?*

## At a glance

|                                | Hasura                                                          | pgrls                                                  |
| ------------------------------ | --------------------------------------------------------------- | ------------------------------------------------------ |
| Authorization layer            | Hasura Engine (metadata-driven, role+permission rules)          | Postgres database (RLS policies + grants)              |
| Where rules live               | Hasura metadata (Git-versioned via Hasura CLI)                  | Postgres `CREATE POLICY` statements                    |
| Enforced by                    | Hasura Engine, before the query reaches Postgres                | Postgres planner, for every query                      |
| Bypasses Hasura?               | n/a                                                             | Direct DB connections bypass Hasura entirely           |
| Lintable by pgrls?             | No — pgrls reads the DB, not Hasura metadata                    | n/a                                                    |
| Recommended for defence-in-depth? | Some teams add RLS on top                                    | Catches the RLS layer if you have one                  |

## When pgrls is relevant to a Hasura project

Two scenarios:

### 1. You use Hasura permissions only — pgrls has nothing to add

If your Hasura app does all its authorization via Hasura permissions
and no Postgres user ever connects directly (no admin tooling, no BI
tools, no Celery workers, no `psql` for debugging in production),
then RLS is an empty defence-in-depth layer and pgrls has nothing to
audit. The Hasura permissions are where the policy decisions live;
auditing those is a Hasura-tooling problem, not a Postgres one.

### 2. You use RLS as defence-in-depth under Hasura — pgrls is the audit layer

A growing pattern: declare RLS policies on the Postgres tables Hasura
fronts, so that even if a non-Hasura client connects directly (a
backup script, an analyst's `psql` session, a Lambda task, a
compromised Hasura admin token), the database refuses to return the
wrong rows. RLS is the floor under Hasura's ceiling.

This is the pattern pgrls is built for. In this setup, pgrls runs
against the same Postgres Hasura connects to and validates that the
RLS layer doesn't have the bugs that ship past code review — the
same 43 rules apply (SEC004, SEC027, SEC030, SEC018, PERF001/003/004,
VIEW001–004, …).

## What Hasura does that pgrls does not

- **Role+permission rules in metadata** — declared in Hasura, edited
  in the Hasura console, version-controlled via the Hasura CLI.
- **GraphQL-level enforcement** — permissions narrow the GraphQL
  surface (which fields, which row filters) before the query reaches
  Postgres.
- **Engine-side auditing** — Hasura has its own validation for
  permission consistency (e.g., the console flags conflicts).

## What pgrls does that Hasura does not

- **Static analysis of Postgres RLS policies.** Hasura permissions
  are separate from RLS; pgrls only sees the RLS layer.
- **Reads what the database itself will enforce** — orthogonal to
  what Hasura's metadata says, and the only thing that matters when a
  non-Hasura client connects directly.
- **CI-native rule enforcement** for the bugs that ship past code
  review (SEC004 et al.).

## When you'd use pgrls on a Hasura project

- **If you've added RLS as defence-in-depth under Hasura** (the
  common pattern for teams worried about non-Hasura DB access),
  pgrls is the audit layer for that RLS.
- **If you're migrating off Hasura** to direct-Postgres access
  (PostgREST, a custom backend), the RLS layer becomes load-bearing
  and pgrls is the way to verify it before the cutover.
- **If you allow analyst tools or admin scripts to connect directly
  to Postgres**, RLS is the only authorization mechanism that
  applies to them — pgrls audits whether it works.

## Honest summary

Hasura permissions and RLS are different layers, not interchangeable.
pgrls only audits the RLS half. For a Hasura-only setup with no
direct DB access, pgrls has nothing to do; for any setup that uses
RLS as defence-in-depth (which is a good idea), pgrls is the audit
tool.
