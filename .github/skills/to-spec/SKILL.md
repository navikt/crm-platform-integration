---
name: to-spec
description: Turn an agreed Salesforce feature request into a concise repository feature specification.
disable-model-invocation: true
---

# Salesforce feature specification

Use this skill after the request and intended behaviour are sufficiently clear. Do not publish or edit Salesforce metadata while writing the spec.

## Process

1. Read `CONTEXT.md`, relevant ADRs under `docs/adr/`, and the nearest implementation and tests.
2. State the user problem and the observable outcome.
3. Identify the highest useful behavioural test seam: LWC DOM/event, Apex public method, integration boundary, or metadata validation.
4. Record success, error, security, data-handling, and out-of-scope behaviour.
5. Write the spec under `.github/specs/<feature-slug>.md`.
6. Ask for human confirmation before publishing or linking a GitHub Issue when the request changes access, personal-data handling, authentication, callouts, metadata visibility, CI, or package boundaries.

## Required sections

- Problem statement
- Desired user-visible outcome
- User stories
- Acceptance criteria
- Behavioural test seam
- Implementation decisions
- Security and data considerations
- Testing decisions
- Out of scope
- Open questions

Do not include secrets, real personal data, invented Salesforce IDs, or implementation detail that is not a decision.
