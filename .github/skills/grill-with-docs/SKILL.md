---
name: grill-with-docs
description: 'Use when the user requests grill, grill with docs, or a critical clarification round for a Salesforce feature or design. Resolve decisions in dependency order and record agreed terminology and tradeoffs.'
disable-model-invocation: true
---

# Clarify with repository docs

Use this skill before a non-trivial feature, integration, data, access, or architecture change.

## Process

1. Read `CONTEXT.md`, relevant ADRs under `docs/adr/`, and the nearest implementation and tests. Respect package-owned reference boundaries.
2. Restate the outcome and separate verified facts, user-approved decisions, proposals, and open questions. Do not ask the user to repeat decisions already made.
3. Map the decisions and their prerequisites. Include actor, observable outcome, scope, failure paths, data, access, package boundaries, test seam, and operational ownership where relevant.
4. Look up facts in code or authoritative documentation yourself. Report unavailable evidence; do not turn a guess into a fact. Use `codebase-design` when interface or responsibility choices need deeper analysis.
5. Use the question tool to ask one focused round containing only decisions whose prerequisites are resolved. Give a recommended answer and its tradeoff for each question. Dependent questions wait for the next round.
6. Recompute the open decisions after each answer. Test the proposed behaviour with concrete success, error, and misuse scenarios. Challenge ambiguous domain terms against `CONTEXT.md`; do not silently rename established concepts.
7. Record agreed stable terminology in `CONTEXT.md`, not session notes or speculative implementation detail. Offer a dated ADR only for a consequential tradeoff that is costly to reverse or surprising without its rationale. Preserve existing ADR status and obtain approval before treating a proposal as accepted.
8. Finish with a concise decision summary, explicit exclusions, test seam, and any remaining blockers. Ask the user to confirm shared understanding. Silence is not approval; unresolved branches remain visible.
9. After confirmation, hand the outcome to the user-invoked `to-spec` workflow. Do not automatically invoke another user-only skill or implement directly from the interview.

Access, personal-data, authentication, callout, metadata-visibility, CI, deployment, and package decisions require explicit human approval. Agreement on a design does not authorize org operations, issue publication, or package release.

Do not invent domain terms, Salesforce IDs, external contracts, or policy requirements. Do not create a second glossary or a generic interview-notes document unless requested.

## Reference

Locally maintained Salesforce adaptation, informed by [Matt Pocock's engineering skills](https://github.com/mattpocock/skills). Upstream is a reference, not a runtime dependency or permission to override repository rules.
