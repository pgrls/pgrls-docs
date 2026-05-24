---
title: "+ Supabase"
parent: Comparisons
nav_order: 110
permalink: /comparisons/supabase/
---

# pgrls vs. Supabase

**Not "vs." — pgrls audits the policies you write with Supabase.**

[Supabase](https://supabase.com) is a Backend-as-a-Service built
around Postgres + RLS — it provides the database, the auth layer
(`auth.uid()` / `auth.role()` / `auth.jwt()`), the storage layer, the
realtime channels, the `anon` / `authenticated` / `service_role`
roles, and the dashboard for managing policies. RLS is the
load-bearing authorization mechanism in a Supabase app.

What Supabase **does not** ship is a linter for the RLS policies you
write. The official RLS guide
([supabase.com/docs/guides/database/postgres/row-level-security](https://supabase.com/docs/guides/database/postgres/row-level-security))
shows policy patterns, recommends `auth.uid() IS NOT NULL AND
auth.uid() = user_id` to prevent silent failures for unauthenticated
users, and points at the community
[`usebasejump/supabase-test-helpers`](https://github.com/usebasejump/supabase-test-helpers)
repo for testing — but there is no "is my policy actually correct?"
checker in the Supabase CLI, dashboard, or docs.

**pgrls** is that checker. It connects to a Supabase database (any
Postgres, really — Supabase is just the most common deployment surface)
and runs 43 rules over every policy.

## At a glance

|                            | Supabase                                                    | pgrls                                                                  |
| -------------------------- | ----------------------------------------------------------- | ---------------------------------------------------------------------- |
| Role                       | Hosted Postgres + auth + storage + realtime + dashboard     | Static analyzer for the policies in that Postgres                      |
| Provides the RLS engine    | Yes (Postgres RLS, via the `auth.*` helpers)                | No — only audits                                                       |
| Ships an RLS linter        | No                                                          | Yes                                                                    |
| Cost                       | Hosted SaaS (free tier + paid plans)                        | MIT-licensed open source                                               |
| Testing recommendation     | Community `supabase-test-helpers` (pgTAP / dbdev)           | `pgrls.testing` pytest plugin (role switching + isolation assertions)  |
| Where the bug is caught    | Runtime, in production, when a user notices                 | CI, before the policy ever ships                                       |

## The bugs Supabase docs already warn about — and pgrls catches

The Supabase docs explicitly call out that `auth.uid()` returns
`NULL` for unauthenticated requests, and they recommend writing
`auth.uid() IS NOT NULL AND auth.uid() = user_id`. That's exactly
the warning behind **SEC004**: the moment a policy is written as
`auth.uid() IS NULL OR user_id = auth.uid()` (the natural-language
inversion that looks correct in English), it admits every row to
anonymous clients. The docs flag it as a footgun; pgrls flags it as
a CI-blocking finding.

Beyond SEC004, pgrls covers the patterns Supabase docs don't
explicitly call out:

- **SEC027** — tenant-scoped policies that forget per-user scoping
  inside a tenant.
- **SEC030** — nullable discriminator columns that silently hide
  rows (and that flip to *exposing* them under any NULL-tolerant
  policy form).
- **SEC018** — `current_user` used as a tenant key (which collapses
  under Supabase's connection pooling and shared roles).
- **PERF001** — `auth.uid()` evaluated per row instead of wrapped in
  `(SELECT auth.uid())` (the docs *do* recommend the wrapper for
  performance; pgrls flags every policy that didn't get the memo).
- **PERF003 / PERF004** — policies filtering on un-indexed or
  function-wrapped columns that defeat plain B-tree indexes.

## When you'd use pgrls on a Supabase project

- **Pre-launch RLS audit.** Run `pgrls lint` against your project
  before opening the service to real users. Catches the policies
  that "look correct" but leak.
- **CI gate on every PR.** Apply your migrations to a CI Postgres
  (or `supabase start` a local stack), then run pgrls. New policies
  are checked the same way you'd check unit tests.
- **Adopting on an existing project.** `pgrls lint --baseline`
  records what's currently flagged so CI only fails on *new*
  findings — adopt today without a clean-up sprint.

## See also

- The [Supabase recipe in the pgrls repo](https://github.com/pgrls/pgrls/blob/main/docs/recipes/supabase.md)
  walks through `supabase start`-based CI + the SEC004 + SEC027 +
  SEC030 trio that dominates Supabase RLS bugs.

## Honest summary

pgrls is built specifically for the Supabase pattern of
RLS-as-authorization. Supabase ships the engine; pgrls ships the
checker. Using both is the obvious move.
