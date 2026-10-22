---
name: diagnosing-bugs
description: Diagnose Salesforce and LWC bugs with a tight red-capable feedback loop before changing production code.
---

# Diagnose Salesforce bugs

Use this skill when behaviour is broken, failing, throwing, or unexpectedly slow.

## Process

1. Read `CONTEXT.md`, relevant ADRs, and the nearest implementation and test.
2. Build one fast, deterministic feedback loop at the highest available seam. Prefer an Apex test, focused LWC Jest test, deployment preview, or reproducible CLI/browser check.
3. Run the loop and capture the exact user-visible symptom. Redact secrets, tokens, personal data, and org identifiers.
4. Minimise the reproduction before forming a fix.
5. State three to five falsifiable hypotheses and test the cheapest distinguishing prediction first.
6. Add or update a regression test before the production fix when a correct seam exists.
7. Apply the smallest fix, rerun the focused check, then run the relevant broader validation.
8. Remove temporary instrumentation and report blocked org-dependent checks explicitly.

## Salesforce boundaries

- Do not use real personal data or hardcoded Salesforce IDs in reproductions.
- Do not change package-owned directories without approval.
- Treat access control, authentication, callouts, personal data, metadata visibility, and deployment as red-zone work.
- Never claim an Apex test or deployment passed without an authenticated org command completing successfully.
