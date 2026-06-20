# write-probe-demo.tape — VHS script for the verify screencast (docs/website).
#
# Render from the pgrls-docs repo root:
#     vhs assets/write-probe-demo.tape
#
# Prereqs: docker, psql, vhs, and a pgrls >= 0.39.0 (write-mode + --probe).
# The hidden block below puts the local pgrls .venv on PATH — edit that path
# for your machine, or drop it if `pgrls --version` is already >= 0.39.0.

Output assets/write-probe-demo.gif

Set Shell "bash"
Set FontSize 15
Set Width 1400
Set Height 780
Set Padding 24
Set TypingSpeed 28ms

# --- hidden setup: PATH, a throwaway Postgres, and a write-leaky policy ---
Hide
Type "export PATH=/Users/dmitry.maranik/IdeaProjects/pgrls/.venv/bin:$PATH" Enter
Type "export DATABASE_URL=postgresql://postgres:postgres@localhost:55450/postgres" Enter
Type "bash assets/write-probe-demo.sh setup" Enter
Sleep 15s
Type "export PS1='$ '" Enter
Type "clear" Enter
Show

# --- the demo ---
Sleep 800ms
Type "# pgrls PROVES cross-tenant WRITE isolation, over each policy's WITH CHECK." Enter
Sleep 1.8s
Type "# Reads are tenant-scoped, but this write-check's OR admits another tenant. Prove it:" Enter
Sleep 1.6s
Type "pgrls verify --mode write" Enter
Sleep 4.5s
Type "# A real LEAK + the exact counterexample. Confirm it against the LIVE database:" Enter
Sleep 1.6s
Type "pgrls verify --mode write --probe" Enter
Sleep 7s
Type "# LEAK CONFIRMED: the cross-tenant write was actually admitted. Now fix the WITH CHECK:" Enter
Sleep 1.6s
Type "bash assets/write-probe-demo.sh fix" Enter
Sleep 4s
Type "# Re-verify: proven by Z3 AND agreed by the live probe:" Enter
Sleep 1.4s
Type "pgrls verify --mode write --probe" Enter
Sleep 7s
Type "# PROVEN + AGREE: the write is now rejected, confirmed against reality." Enter
Sleep 3.5s

# --- hidden teardown ---
Hide
Type "bash assets/write-probe-demo.sh teardown" Enter
Sleep 3s
