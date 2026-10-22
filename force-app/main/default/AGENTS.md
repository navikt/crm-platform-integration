# Instructions for `force-app/main/default`

These instructions supplement [`force-app/AGENTS.md`](../../AGENTS.md) and the
root [`AGENTS.md`](../../../AGENTS.md). Follow all three when working in this
directory.

This directory uses Salesforce DX source structure for shared package
metadata, including classes, triggers, objects, custom metadata, permissions,
layouts, tabs, translations, and static resources.

## Directory-specific guidance

-   Keep metadata and Apex changes in their existing Salesforce source-format
    locations. Preserve API names, metadata names, and existing public contracts.
-   Check related classes, triggers, metadata, and colocated tests before
    changing shared behavior. Prefer the package's existing utilities and
    established patterns over creating parallel implementations.
-   Keep triggers focused on event dispatch and delegate business logic to
    cohesive handlers or services.
-   Treat permission sets, sharing, field-level security, metadata access, and
    externally reachable Apex as security-sensitive. Make access decisions and
    error behaviour explicit.
-   Do not assume a package namespace or add a domain-specific prefix that is not
    already established by the relevant feature or integration.
-   Keep test classes beside the code they cover, following current repository
    structure. Use the Apex and test standards in
    [`.github/instructions/salesforce-apex.instructions.md`](../../../.github/instructions/salesforce-apex.instructions.md)
    and
    [`.github/instructions/salesforce-testing.instructions.md`](../../../.github/instructions/salesforce-testing.instructions.md).

Do not move code into or out of this directory as part of an unrelated change.
For package ownership, org safety, validation, and approval requirements, use
the parent instructions.
