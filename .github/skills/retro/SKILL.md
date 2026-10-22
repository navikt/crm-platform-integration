---
name: retro
description: 'Use when the user requests a retrospective of an agent session, missed skills, repeated mistakes, excessive exploration, or improvements to the Salesforce development workflow.'
disable-model-invocation: true
---

# Agent workflow retrospective

Review how the work was performed, not only the resulting code. Propose improvements first; a retrospective is not authorization to edit policy, install tooling, or change CI.

## Process

1. Establish the requested session or period; default to the current conversation. Use available session history for past work. Read the relevant request, decisions, tool outcomes, and actual validation evidence.
2. Read the repository's instructions, existing skills, and relevant validation commands before declaring anything missing. A skill file on disk, its discovery by the host, and its actual invocation are different facts.
3. Identify concrete friction: missed navigation pointers or skills, unresolved requirements, duplicate instructions, unnecessary tool calls, weak test feedback, hidden org prerequisites, or inaccurate completion claims.
4. For each finding state the observed evidence, consequence, likely cause, smallest improvement, and how to verify that improvement. Mark uncertainty; do not infer a host failure from a single failed skill-name lookup.
5. Prefer deterministic existing checks for mechanical errors. Use instructions for judgement and workflow, not as a substitute for tests or executable validation. Do not add a new tool when the existing one is simply unwired or unused.
6. Rank a short list by impact and recurrence. Include what worked and avoid recommendations that merely add files or repeat existing rules.
7. Ask which changes the user approves before implementation. Any CI/auth, org operation, dependency, or package change retains its separate approval gate.

## Salesforce and repository boundaries

- Distinguish local Jest/static checks from org-dependent Apex and metadata validation.
- Never recommend production testing or use another org to bypass a blocked check.
- Keep stable terms in `CONTEXT.md`, operational rules in instructions, and consequential architecture choices in ADRs. Avoid parallel sources of truth.
- Use existing approved history and repository tools; do not upload code, session logs, or personal data to external analysis services.
- Report proposed, implemented, and verified improvements separately. Do not claim a skill is discoverable in VS Code solely because its frontmatter validates.

## Reference

Locally maintained Salesforce adaptation informed by [Matt Pocock's retro skill](https://github.com/mattpocock/skills/tree/main/skills/engineering/retro). The skill works without upstream installation.
