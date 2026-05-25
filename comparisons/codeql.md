---
title: "vs CodeQL"
parent: Comparisons
nav_order: 50
permalink: /comparisons/codeql/
---

# pgrls vs. CodeQL — do I need both?

**Short answer: yes, and they share a UI.** CodeQL scans your
application source for security bugs and ships findings to GitHub
Code Scanning. pgrls scans your live Postgres for RLS bugs and emits
SARIF — which lands in the same Code Scanning UI.

## The kind of bug each one catches

**CodeQL** ([github.com/github/codeql](https://github.com/github/codeql))
fires on app-layer bugs like this:

```python
# Code Scanning surfaces this:
@app.route("/doc/<id>")
def get_doc(id):
    return db.execute(f"SELECT * FROM docs WHERE id = {id}")
    # ← Tainted user input flows into raw SQL.
```

Standard library covers 8 languages (C/C++, C#, Go, Java, JS,
Python, Ruby, Rust) — no built-in queries for Postgres RLS.

**pgrls** fires on bugs in the database that's supposed to backstop
the above:

```sql
CREATE POLICY tenant_read ON public.documents
    FOR SELECT
    USING (auth.uid() IS NULL OR owner_id = auth.uid());
```

Even if CodeQL catches and the team fixes the SQL injection, the
policy that *should* refuse to return the wrong rows still doesn't.
pgrls flags it as **SEC004**.

## Capability check

|                                     | CodeQL | pgrls |
| ----------------------------------- | :---:  | :---: |
| App-code SAST in 8 languages        | ✓      | —     |
| Catches RLS bypass / row-leak bugs  | —      | ✓     |
| Reads source files                  | ✓      | —     |
| Reads live Postgres catalog         | —      | ✓     |
| SARIF output                        | ✓      | ✓     |
| GitHub Code Scanning native         | ✓      | ✓ (via `upload-sarif`) |

## Wire pgrls into Code Scanning

One YAML block lands pgrls findings in the same dashboard CodeQL
ships to:

```yaml
- uses: pgrls/pgrls-action@v1
  with:
    format: sarif
    output: pgrls.sarif
  continue-on-error: true
- uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: pgrls.sarif
```

Findings from both tools land in the same Security tab, scoped by
distinct "tool" labels. PR reviewers see CodeQL's SAST findings and
pgrls's RLS findings side by side, same UI, same triage flow.

## Verdict

Use both. CodeQL covers what your code does; pgrls covers what your
database enforces. The SARIF integration means there's no second
dashboard to maintain.
