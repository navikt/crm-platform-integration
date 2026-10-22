# Salesforce package instructions: crm-platform-integration

These instructions apply to the `crm-platform-integration` Unlocked Package
source under `force-app/`. Repository-wide policies are in the root
[`AGENTS.md`](../AGENTS.md); follow both.

## Package source layout

-   Source is grouped by feature and integration. Keep production code, metadata,
    and tests with the corresponding area, following nearby conventions.
-   `main/default/` contains shared package metadata and code. Its additional
    instructions are in [`main/default/AGENTS.md`](main/default/AGENTS.md).
-   Other top-level directories under `force-app/` represent feature and
    integration areas. Do not reorganize or rename them without an approved
    migration plan.
-   Keep package dependencies and aliases consistent with the root
    [`sfdx-project.json`](../sfdx-project.json). Do not modify separately owned
    package directories identified in
    [`.copilot/reference-only.instructions.md`](../.copilot/reference-only.instructions.md)
    without explicit user approval.

## Apex and Salesforce metadata

-   Follow the detailed, file-specific standards under
    [`.github/instructions/`](../.github/instructions/), especially the Apex,
    metadata, and Salesforce testing instructions.
-   Use `with sharing` by default, bulkify SOQL and DML, and keep queries and DML
    outside loops.
-   Keep triggers thin and delegate business logic to an appropriate handler or
    service. Reuse established package utilities and error-logging patterns.
-   Protect public entry points, including `@AuraEnabled`, REST, invocable, and
    callout boundaries, with appropriate validation, access checks, and explicit
    error handling.
-   Preserve existing public Apex APIs and metadata names. Do not invent a
    namespace or introduce a new naming prefix; follow the established
    conventions of the feature being changed.
-   Do not hardcode Salesforce IDs, org-specific URLs, credentials, package
    installation keys, or personal data.

## Behavioural changes

-   Add or update focused tests for behaviour changes. Apex tests are currently
    colocated with their related feature or integration; follow that layout.
-   Use `System.Assert.*` and `System.Test.*` in Apex tests. Include a
    `System.runAs` test with a minimum-access user when the behaviour does not
    require elevated permissions.
-   Use the red-green-refactor workflow in
    [`.github/skills/tdd-salesforce/SKILL.md`](../.github/skills/tdd-salesforce/SKILL.md).
-   Report org-dependent Apex checks that could not run. Do not claim they passed
    without successful execution.

For local validation commands and org-safety requirements, see the root
[`AGENTS.md`](../AGENTS.md).
