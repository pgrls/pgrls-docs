---
title: "vs Semgrep"
parent: Comparisons
nav_order: 40
permalink: /comparisons/semgrep/
---

# pgrls vs. Semgrep — do I need both?

**Short answer: yes.** Semgrep scans your *application code* for
security bugs. pgrls scans your *live database* for RLS bugs. They
operate on different artifacts and never overlap.

## The kind of bug each one catches

**Semgrep** ([github.com/semgrep/semgrep](https://github.com/semgrep/semgrep))
fires on application-code bugs like this:

```python
# Python view code Semgrep catches:
def get_doc(request, doc_id):
    sql = f"SELECT * FROM documents WHERE id = {doc_id}"
    return db.execute(sql)   # ← SQL injection
```

It pattern-matches across 30+ languages and configs. The standard
rule registry targets app-layer issues: injection, auth-bypass,
hardcoded secrets, dangerous deserialization.

**pgrls** fires on bugs in the database that's supposed to *backstop*
mistakes like the one above:

```sql
CREATE POLICY tenant_read ON public.documents
    FOR SELECT
    USING (auth.uid() IS NULL OR owner_id = auth.uid());
```

That policy admits every row to anonymous clients. Semgrep has no
rule for it and structurally can't — the artifact is a row in
Postgres's `pg_policy` catalog, not source text. pgrls flags it as
**SEC004**.

## Capability check

|                                          | Semgrep | pgrls |
| ---------------------------------------- | :---:   | :---: |
| App-code security across many languages  | ✓       | —     |
| Catches RLS bypass / row-leak bugs       | —       | ✓     |
| Reads source files                       | ✓       | —     |
| Reads live Postgres catalog              | —       | ✓     |
| Auto-fix                                 | ✓       | ✓ (12 of 46 rules) |

## Why you can't just write RLS rules in Semgrep

Three structural limits:

1. **The artifact is wrong.** RLS policies live in `pg_policy` —
   not in source files. On Supabase, many policies are created via
   the dashboard with no source file at all.
2. **The detection needs a real parser.** "Is `auth.uid()` on the
   left of an `IS NULL OR …` disjunct at the top level of this
   `USING` clause?" is a tree walk over `pglast`'s AST, not a text
   pattern.
3. **You can't catch what isn't there.** Detecting *missing*
   per-user scoping needs schema metadata (column nullability,
   indexes, role grants) that Semgrep doesn't have access to.

## Verdict

Use both. Semgrep on the caller; pgrls on the callee. Their findings
land in disjoint artifacts, so no collision and no duplication.
