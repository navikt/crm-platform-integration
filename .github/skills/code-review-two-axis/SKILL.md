---
name: code-review-two-axis
description: Review Salesforce changes against the repository standard and the originating specification as separate axes. Use for pull requests, branches, work in progress, or before commit.
---

# Two-axis Salesforce review

Keep standards and specification separate so that one cannot hide the other.

## Fixed point

1. Ask for or identify the comparison point, such as `main`, a commit, or a branch.
2. Confirm the reference exists and capture the merge-base diff.
3. Identify the originating issue, request, or specification. If none exists, report that the specification axis is limited.

## Standards axis

Review against, in order:

-   `AGENTS.md` in the repository root.
-   `force-app/AGENTS.md` for Salesforce package source.
-   `force-app/main/default/AGENTS.md` for additional rules in that directory.
-   `.copilot/reference-only.instructions.md` for package ownership boundaries.
-   Applicable files under `.github/instructions/`.
-   Existing Salesforce metadata, Apex, LWC, Jest, and workflow patterns.

Flag security and operational risks, including hardcoded credentials or IDs, PII in logs or fixtures, weakened sharing or access checks, SOQL/DML in loops, unhandled `@AuraEnabled` errors, removed assertions, skipped tests, unsafe callouts, package-boundary violations, and deployment or workflow guards that were weakened.

For architecture and design changes, assess Salesforce Well-Architected dimensions: Trusted (secure, compliant, reliable), Easy (intentional, maintainable/readable, appropriately automated), and Adaptable (resilient, separated/composable, packageable). Require the change to make important tradeoffs and public contracts understandable.

For new or materially changed Apex, check Nav Platforce naming conventions and ApexDoc coverage. Flag new public classes, methods, constructors, properties, or annotated entry points that lack a concise ApexDoc contract where documentation would clarify purpose, parameters, returns, exceptions, sharing, or platform behaviour.

## Specification axis

Check separately:

-   requested behaviour that is missing or partial;
-   behaviour added without a requirement;
-   edge cases and error paths that the request implies but the change does not cover;
-   tests that demonstrate the user-visible contract.

## TDD and test quality

Check whether the change has a focused behavioural test at the correct seam. Treat a missing red-to-green record as a process gap when the environment could have supported it. Distinguish that gap from an environment blocker, such as a missing authenticated org for Apex tests.

## Report

Report findings first, ordered by severity, with file links and concise evidence. Separate `Standards` and `Spec`. Mark judgement calls as such. End with the checks run, checks blocked, and residual risk. Do not claim deployment, package installation, or Salesforce test success unless the command completed successfully.
