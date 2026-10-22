## Summary

<!-- What changed and why? Link the originating issue or specification. -->

## Scope

-   [ ] Main package only (`force-app/`)
-   [ ] Package-owned or reference-only content changed with explicit approval
-   [ ] Metadata/API/public contract changed
-   [ ] CI, authentication, deployment, package, or environment configuration changed

## TDD and validation

-   [ ] Behavioural seam identified
-   [ ] Focused test added or updated before implementation where an executable seam exists
-   [ ] Red result observed before implementation, or the environment blocker is explained below
-   [ ] Focused check rerun after implementation
-   [ ] Relevant broader validation run

Checks run:

```text
<!-- Include exact commands and results. Never include credentials, tokens, package keys, or personal data. -->
```

Blocked checks or org prerequisites:

```text
<!-- State the exact command and prerequisite. Do not describe blocked checks as passed. -->
```

## Review

### Runbook and operational changes

-   [ ] Runbook added or updated for manual steps or Team Platforce actions, or not applicable
-   [ ] Metadata API names and old/new names for renamed or deleted metadata are listed in the runbook, or not applicable
-   [ ] SIT2 cleanup verification is documented, or is clearly pending with an owner
-   [ ] Production cleanup/verification is assigned to Team Platforce, and evidence is recorded or clearly pending
-   [ ] Scripts Team Platforce may run are committed, tested, verified, reviewed, and approved before execution, or not applicable
-   [ ] No direct production metadata change was made without explicit Team Platforce authorization
-   [ ] No secrets or personal data are included in scripts, runbooks, or evidence

### Standards

-   [ ] Nav Platforce naming and Salesforce source conventions followed
-   [ ] ApexDoc added or updated for new or materially changed public Apex contracts
-   [ ] Sharing, access control, FLS, Experience Cloud visibility, and data handling reviewed where relevant
-   [ ] No hardcoded IDs, credentials, URLs, package keys, or personal data
-   [ ] Bulk safety, callout handling, error handling, and logging reviewed
-   [ ] Salesforce Well-Architected considered: Trusted, Easy, Adaptable
-   [ ] Clean code: focused responsibilities, readable names, shallow control flow, no speculative abstractions

### Specification

-   [ ] Requested behaviour is covered
-   [ ] Success and relevant error paths are covered
-   [ ] No unrelated behaviour or refactoring included
-   [ ] Residual risk and follow-up work are recorded

## Human approval

<!-- Confirm the exact target and action with a human before any non-production org interaction. Production access is always prohibited. Package operations, CI/auth changes, and changes to package-owned content also require human approval. -->

-   [ ] Required human approval obtained
-   [ ] Not applicable
