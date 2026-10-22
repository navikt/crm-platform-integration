---
name: implement
description: Implement an approved Salesforce spec or ticket set with focused TDD slices and a final two-axis review.
disable-model-invocation: true
---

# Implement approved Salesforce work

Use this skill only when the behaviour, scope, and test seams are agreed.

## Process

1. Read the approved spec under `.github/specs/`, linked GitHub Issues, `CONTEXT.md`, relevant ADRs, and applicable instructions.
2. Confirm package ownership and classify red-zone work.
3. Work one unblocked vertical slice at a time using `.github/skills/tdd-salesforce/SKILL.md`.
4. Run the focused check after each implementation change.
5. Keep Apex org-dependent validation separate from local Jest and static checks.
6. Run the relevant broader validation at the end.
7. Apply `.github/skills/code-review-two-axis/SKILL.md` before commit or pull request.
8. Stop before deployment, package, CI/auth, or other human-approval actions.

Completion requires the focused and broader checks to be reported, with blocked org prerequisites named exactly. Do not close GitHub Issues automatically.
