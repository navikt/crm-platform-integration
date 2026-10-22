---
name: setup-matt-pocock-skills
description: Verify and maintain the repository-specific configuration used by the adapted engineering skills.
disable-model-invocation: true
---

# Setup adapted engineering skills

Use this skill when the repository's AI workflow, issue tracker, or documentation locations change.

## Repository decisions

-   General Nav guidance may come from user scope or a Nav collection.
-   Salesforce package and repository-specific guidance lives in this repository.
-   Local build and test commands must work without an external collection.
-   GitHub Issues are the system of record for work items.
-   Short feature specifications belong in `.github/specs/`.
-   Architecture decision records belong in `docs/adr/`.
-   Stable domain and architecture context belongs in `CONTEXT.md`.

## Verification

1. Read `AGENTS.md`, `CONTEXT.md`, and `.github/AI-SETUP-TODO.md`.
2. Confirm the paths and issue-tracker decision agree across those files.
3. Check that repository-specific instructions do not require network access for build or test.
4. Report conflicts and ask before changing governance decisions.

Do not install or copy the complete upstream skill collection. Keep this repository's Salesforce adaptations small and explicit.
