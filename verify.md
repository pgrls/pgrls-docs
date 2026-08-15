---
title: Verify — the prover
layout: default
nav_order: 2
permalink: /verify/
description: pgrls verify proves Postgres RLS tenant-isolation with the Z3 SMT solver — reads and writes — and confirms the proof against a live database.
---

# `pgrls verify` — prove isolation, don't just lint it

Most of pgrls *lints*: it pattern-matches your policies against a catalog of
rules. `pgrls verify` does something no other RLS tool does — it runs the
**Z3 SMT solver** over a policy's predicate and *proves* a tenant-isolation
property, or hands back a **concrete counterexample row** when the proof fails.

Five threat models (`--mode`), each its own proof:

- **`--mode anon`** (default) — can an *unauthenticated* session read any row?
- **`--mode cross-tenant`** — can a session authenticated as one tenant read a
  *different* tenant's row?
- **`--mode write`** — can such a session *write* a row stamped for another
  tenant? A write crosses tenants two ways, so both gates are proven: the
  `WITH CHECK` that decides what row may be left behind, and the `USING` that
  decides which *existing* rows the session may reach. The
  account-takeover-adjacent footgun no other tool checks.
  *(pgrls ≥ 0.39.0; the `USING` gate since 0.53.0.)*
- **`--mode escalation`** — can a low-trust role that is a *member of a table's
  owner* bypass RLS on the owner's not-`FORCE`'d tables (the reachable SEC048
  privilege-escalation path, plus the anon-callable `SECURITY DEFINER` SEC042
  case)? Proves or refutes the static reachability finding; `--probe` live-
  confirms it via a real `SET ROLE` chain. *(pgrls ≥ 0.45.0.)*
- **`--mode reachability`** — a table's policies can deny anonymous reads and
  a **view** over it still hand them out. A `security_invoker = false` view runs
  as its *owner*, so an anon-selectable one owned by an RLS-exempt role returns
  every row the policies were written to withhold. Proves whether that second
  door is open — gated on the owner actually being exempt, so a view owned by an
  ordinary role, or one over a `FORCE`'d table, stays silent.
  *(pgrls ≥ 0.54.0.)*

Every table gets one of three **honest verdicts**:

- **PROVEN** — Z3 proved isolation holds.
- **LEAK** — with the exact counterexample row that breaks it.
- **UNVERIFIED** — the predicate is outside the decidable fragment, so the
  verifier *degrades to the linter*. It never bluffs.

## Watch it: proving — and live-confirming — cross-tenant write isolation

![pgrls verify --mode write and --probe, end to end]({{ '/assets/write-probe-demo.gif' | relative_url }})

The policy under test scopes *reads* to the caller's tenant, but its `WITH CHECK`
has an `OR` that lets a caller `INSERT` a row owned by **another** tenant:

1. `pgrls verify --mode write` proves the **LEAK** and prints the counterexample.
2. `pgrls verify --mode write --probe` **confirms it against the live database**:
   it connects as the threat-model session, attempts the cross-tenant write, and
   reports `LEAK CONFIRMED` when the write is actually admitted.
3. After tightening the `WITH CHECK`, the same commands return **PROVEN**, and
   the probe **AGREE**s — the write is now rejected, confirmed against reality.

`--probe` keeps the static proof honest: anything it cannot reproduce live it
*abstains* on cleanly — never a false confirmation. *(pgrls ≥ 0.39.0.)*

## Soundness over recall

`verify` is a proof, not a heuristic: it never reports a leak it cannot exhibit,
and never reports isolated unless Z3 proves it. Drop it in CI as a hard
tenant-isolation gate — it exits non-zero on any leak (and, under `--strict`, on
`UNVERIFIED` too). On a `LEAK`, `pgrls verify --emit-repro` writes a runnable
`.sql` + pytest that reproduces it. For everything outside the decidable
fragment, the rule-based linter has the rest of the RLS bug space covered.
