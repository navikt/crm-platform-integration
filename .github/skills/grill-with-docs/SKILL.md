---
name: grill-with-docs
description: Clarify a Salesforce feature or design through focused questions while recording domain decisions in CONTEXT.md and ADRs.
disable-model-invocation: true
---

# Clarify with repository docs

Use this skill before a non-trivial feature, integration, data, access, or architecture change.

## Process

1. Read `CONTEXT.md`, relevant ADRs under `docs/adr/`, and the nearest implementation.
2. Ask focused questions about actor, user outcome, constraints, failure paths, data, access, package boundaries, and operational ownership.
3. Distinguish facts, decisions, assumptions, and unresolved questions.
4. Update `CONTEXT.md` only with stable domain or architecture language.
5. Record a consequential choice as a dated ADR under `docs/adr/`.
6. Stop for human approval before access, personal-data, authentication, callout, metadata-visibility, CI, deployment, or package decisions.
7. Hand the agreed outcome to `to-spec` and do not implement directly from an unresolved conversation.

Do not invent domain terms, Salesforce IDs, external contracts, or policy requirements.
