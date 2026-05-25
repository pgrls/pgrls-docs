---
title: "vs Snyk Code"
parent: Comparisons
nav_order: 60
permalink: /comparisons/snyk-code/
---

# pgrls vs. Snyk Code — do I need both?

**Short answer: yes.** Snyk Code is a commercial SAST that scans
your application code. pgrls scans your live database's RLS
policies. They look at different artifacts and never overlap on
findings.

## The kind of bug each one catches

**Snyk Code** ([snyk.io/product/snyk-code](https://snyk.io/product/snyk-code/))
fires on app-layer bugs like this:

```java
// Snyk catches this:
String sql = "SELECT * FROM documents WHERE id = " + userId;
ResultSet rs = stmt.executeQuery(sql);
// ← SQL injection: user input concatenated into a query.
```

It also catches hardcoded secrets, dangerous deserialization, broken
auth patterns. Snyk Code's public documentation does not list any
built-in rules for Postgres Row-Level Security policies.

**pgrls** fires on bugs in the database that's supposed to refuse
the wrong rows even when the application code messes up:

```sql
CREATE POLICY tenant_read ON public.documents
    FOR SELECT
    USING (auth.uid() IS NULL OR owner_id = auth.uid());
```

If a Snyk Code finding gets shipped past review, the database's RLS
should be the last line. This policy isn't — `auth.uid() IS NULL`
admits every row to anonymous clients. pgrls flags it as **SEC004**.

## Capability check

|                                       | Snyk Code | pgrls |
| ------------------------------------- | :---:     | :---: |
| App-layer security across many langs  | ✓         | —     |
| Catches RLS bypass / row-leak bugs    | —         | ✓     |
| Reads source files                    | ✓         | —     |
| Reads live Postgres catalog           | —         | ✓     |
| Cost model                            | Commercial | MIT OSS |
| Output                                | Snyk dashboard + IDE | SARIF / JSON / GH annotations / Markdown / JUnit / text |

## Wire pgrls next to Snyk

Snyk Code lives in its own dashboard. pgrls emits SARIF, which you
can also ingest into Snyk via its custom-finding API — or into
GitHub Code Scanning, where you get a unified view across both.

```yaml
- uses: pgrls/pgrls-action@v1
  with:
    format: sarif
    output: pgrls.sarif
- uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: pgrls.sarif
```

## Verdict

Use both. Snyk Code covers what your code does. pgrls covers what
your database enforces. Either tool catching its finding without
the other still leaves the opposite layer exposed.
