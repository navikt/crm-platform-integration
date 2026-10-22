---
name: to-tickets
description: Break an approved Salesforce feature specification into small GitHub Issues with explicit blocking edges.
disable-model-invocation: true
---

# Salesforce delivery tickets

Use this skill with an approved spec under `.github/specs/`.

## Process

1. Read the spec, `CONTEXT.md`, relevant ADRs, and nearby tests.
2. Split the work into tracer-bullet vertical slices. Each slice must be independently verifiable.
3. Give every ticket a short title, user-visible outcome, acceptance criteria, test seam, and explicit blockers.
4. Present the breakdown for human approval before creating or changing GitHub Issues.
5. Create or update GitHub Issues only after approval. Never invent issue numbers, labels, permissions, or repository settings.
6. Keep package-owned directories and red-zone changes visible in the ticket scope.

## Ticket quality

- Prefer one complete behavioural path over layer-by-layer task lists.
- Keep dependencies explicit and minimal.
- Include focused test and broader validation criteria.
- Record org-dependent prerequisites for Apex, metadata, deployment, or package work.
- Do not close issues automatically.

GitHub Issues are the system of record. Local specs remain the source of the agreed behaviour; the issue should link to the spec when the platform permits it.
