---
title: "+ PostgREST"
parent: Comparisons
nav_order: 120
permalink: /comparisons/postgrest/
---

# pgrls vs. PostgREST

**Not "vs." — pgrls audits the policies PostgREST relies on.**

[PostgREST](https://postgrest.org) turns a Postgres database into a
REST API. Its design choice is uncompromising: *"all authorization
happens in the database."* PostgREST handles authentication (parsing
the JWT, calling `SET ROLE`, populating `request.jwt.claims`); every
authorization decision is delegated to Postgres roles, grants, and
RLS policies. That's elegant — but it puts the entire weight of
authorization correctness on the policies being correct.

What PostgREST **does not** ship is a linter for those policies. The
[auth reference](https://docs.postgrest.org/en/stable/references/auth.html)
documents the JWT model and the `db-pre-request` hook in detail, but
makes no recommendation about how to verify your policies *actually
enforce* what you intend.

**pgrls** is that linter. It connects to the same database PostgREST
serves and runs 43 rules over every policy's `USING` and `WITH CHECK`
predicate.

## At a glance

|                            | PostgREST                                          | pgrls                                                  |
| -------------------------- | -------------------------------------------------- | ------------------------------------------------------ |
| Role                       | HTTP-to-Postgres bridge (auth + role switching)    | Static analyzer for the policies the bridge relies on  |
| Authorization layer        | RLS + grants in the database                       | Audits the RLS half                                    |
| Ships an RLS linter        | No                                                 | Yes                                                    |
| Sets `request.jwt.claims`  | Yes (per request, via `SET LOCAL`)                 | n/a — pgrls reads the policy text and schema           |
| Testing recommendation     | None in official docs                              | `pgrls.testing` pytest plugin                          |
| Where the bug is caught    | First failing request (runtime)                    | CI, before the policy ever ships                       |

## The bugs PostgREST setups consistently ship

Three patterns recur across PostgREST projects in the wild:

1. **`IS NULL OR …` over a missing JWT claim** — policies of the
   shape `current_setting('request.jwt.claims', true) IS NULL OR …`
   admit every row to anonymous clients (the GUC is `NULL` when no
   `Bearer` header is sent). pgrls flags this as **SEC004** —
   `current_setting` is in the default auth-function set.

2. **`current_user` as a tenant key** — in a pooled connection
   model, all signed-in users share a small pool of Postgres roles
   (typically just `authenticated`). A policy comparing
   `owner_role = current_user` collapses across users and lets
   everyone see everyone else's rows. pgrls flags this as **SEC018**.

3. **Nullable discriminator columns** — under
   `tenant_id = current_setting('request.jwt.claim.tenant_id', true)`,
   a row whose `tenant_id` is `NULL` is invisible (NULL = value
   evaluates NULL, not true). The moment any policy uses a
   NULL-tolerant form, those rows become visible to every tenant.
   pgrls flags this as **SEC030**.

## The `db-pre-request` gotcha (orthogonal to RLS but worth flagging)

PostgREST's `db-pre-request` SQL function runs before every
request, typically to populate GUCs from the JWT. If it silently
fails (a swallowed exception, a misconfigured claim), the GUCs are
unset and `current_setting(...) = …` evaluates `NULL = …` → `NULL`
— hiding rows that should be visible. The mirror shape
(`IS NULL OR …`) flips this into exposing rows that should be
hidden. pgrls catches both shapes: SEC004 for the
IS-NULL-OR pattern, SEC030 for nullable discriminator interactions.

## When you'd use pgrls on a PostgREST project

- **At schema-design time.** Run `pgrls lint` after each migration
  applies to a CI Postgres; the policies and grants PostgREST will
  rely on are checked the same way you'd check a unit test.
- **In production audits.** Point pgrls at your prod replica (it's
  read-only) and get the posture summary via `pgrls report`.
- **For the JWT-claim policy patterns specifically.** pgrls's
  default auth-function set includes `current_setting`, so the
  patterns that PostgREST setups gravitate toward (claim-based
  scoping) are first-class.

## See also

- The [PostgREST recipe in the pgrls repo](https://github.com/pgrls/pgrls/blob/main/docs/recipes/postgrest.md)
  has a worked CI workflow + the `db-pre-request` gotcha walk-through.

## Honest summary

PostgREST's design assumes the database's authorization is correct.
pgrls is how you verify that assumption.
