# Agent Instructions: crm-platform-integration

## Project

This repository is a Salesforce DX project for the `crm-platform-integration`
Unlocked Package and references separately owned Unlocked Package dependencies.

The package source is under `force-app/`, organized by feature and integration.
The package directories, versions, and dependencies are declared in
[`sfdx-project.json`](sfdx-project.json). Treat that manifest as the source of
truth. Do not invent or casually change package versions, aliases, or
dependency APIs.

This package includes `KafkaMessage__c` ingestion and asynchronous processing,
along with integrations such as Altinn, PDL, KRR, NORG, SMS, and Felles
kodeverk. See [README.md](README.md) for Kafka message handling and
[runbooks/kodeverk/index.md](runbooks/kodeverk/index.md) for the Kodeverk
runbook.

## Standards hierarchy

Follow all relevant standards. When requirements conflict, apply this order:

1. Current, specific Salesforce-development direction from Team Platforce.
2. Current requirements and practices in
   [Platforce Documentation](https://navikt.github.io/platforce-doc/).
3. Other current Nav standards for Salesforce development and relevant general
   Nav policies.
4. Current Salesforce best practices, official documentation, and the
   [Architecture Center](https://architect.salesforce.com/), including
   [Well-Architected](https://architect.salesforce.com/docs/architect/well-architected/guide/overview),
   where not overridden by relevant Nav or Platforce direction.
5. Repository instructions and established patterns, unless they conflict with
   the standards above or an explicitly approved decision to preserve an
   existing public contract.

Follow every applicable standard that does not conflict. If a conflict has
material or unclear consequences, make it visible and ask for human review.
Preserve deployed public contracts; do not rename existing metadata or public
Apex APIs only to make legacy code conform.

## Source boundaries

-   Make product changes in `force-app/` unless the task explicitly targets
    another area.
-   Keep Apex test classes and reusable Apex test utilities with their matching
    feature or integration area, following the current `force-app/` layout.
-   Treat directories identified in
    [`.copilot/reference-only.instructions.md`](.copilot/reference-only.instructions.md)
    as read-only by default. Read them for context, but do not modify them unless
    the user explicitly approves the change.
-   Do not edit generated, cache, log, scratch-org, or dependency-installation
    output.
-   Never commit secrets, package installation keys, Salesforce credentials,
    session files, or real personal data.
-   Do not change deployment workflows, package versions, dependency versions,
    or production configuration as part of an unrelated code change.

## Repository guidance

Read the applicable detailed instructions before changing code:

-   [Agent workflow](.github/instructions/agentic-development.instructions.md)
-   [Apex](.github/instructions/salesforce-apex.instructions.md)
-   [LWC](.github/instructions/salesforce-lwc.instructions.md)
-   [Salesforce metadata](.github/instructions/salesforce-metadata.instructions.md)
-   [Salesforce tests](.github/instructions/salesforce-testing.instructions.md)
-   [GitHub Actions](.github/instructions/github-actions.instructions.md)
-   [TDD workflow](.github/skills/tdd-salesforce/SKILL.md) for test-first
    feature work
-   [Two-axis code review](.github/skills/code-review-two-axis/SKILL.md) before
    commit or pull-request review

Track remaining agent-setup work in
[`.github/AI-SETUP-TODO.md`](.github/AI-SETUP-TODO.md).

Read [`CONTEXT.md`](CONTEXT.md) before planning feature work, TDD slices, or
architecture reviews. Keep stable domain language and shared verification
vocabulary there; use the detailed instructions and ADRs for rules and
decisions.

Technical documentation is organized under [`docs/`](docs/): architecture
decision records, architecture, domain, surfaces, and integrations. Read
[`docs/README.md`](docs/README.md) to choose the right location and
[`docs/utviklingsstandarder.md`](docs/utviklingsstandarder.md) for the
development standards index.
Use [`docs/arbeidsflyt-og-dokumentasjon.md`](docs/arbeidsflyt-og-dokumentasjon.md)
for the repository's Issue-to-implementation and documentation workflow.

The [README](README.md) documents the Kafka processing flow, including
synchronous handling. Consult it before changing those contracts. Felles
kodeverk usage and operations are described in
[`runbooks/kodeverk/index.md`](runbooks/kodeverk/index.md).
Use [`runbooks/README.md`](runbooks/README.md) and
[`runbooks/template.md`](runbooks/template.md) for manual operations, metadata
renames/deletions, and work that must be performed by Team Platforce.

## Salesforce conventions

### Org safety

-   Before every command that accesses a Salesforce org or environment, ask the
    user to confirm the exact target org/environment and the specific action.
    This includes scratch orgs, sandboxes, Dev Hubs, Apex tests, deploy
    previews, metadata retrievals, deployments, and repository scripts that
    connect to an org.
-   Do not infer permission from an authenticated alias, a configured default,
    previous approval, or repository scripts. Approval for one target or action
    does not authorize another or a later command.
-   Production is always prohibited. Never connect to, query, retrieve from,
    test against, or deploy to a production org, even if requested.
-   If the target or action has not been explicitly confirmed for the current
    operation, stop and ask. Do not run the command.
-   For human-operated production changes, access is not authorization. Do not
    make direct production metadata changes without explicit authorization from
    Team Platforce. This does not permit an AI agent to access production.

### Salesforce development

-   Preserve Salesforce metadata XML and source format. Do not rename metadata
    only to make it look cleaner.
-   Apex must follow the applicable instructions under `.github/instructions/`:
    use `with sharing` by default, bulkify SOQL/DML, avoid hardcoded IDs and
    URLs, and use the established error-logging pattern.
-   Add or update focused Apex tests and LWC Jest tests when behaviour changes.
-   In Apex tests, always use the fully qualified Salesforce namespace:
    `System.Assert.*` for assertions and `System.Test.*` for lifecycle APIs such
    as `System.Test.startTest()` and `System.Test.stopTest()`. Do not use bare
    `Assert` or unqualified `Test` calls.
-   Include at least one `System.runAs(minimumAccessUser)` in Apex test classes
    when the behaviour under test does not require elevated permissions. Use a
    user created from the minimum-access profile
    (`Profile.Name = 'Minimum Access - Salesforce'`) unless the scenario
    genuinely requires a stronger profile.
-   Keep package dependencies and package aliases consistent with
    `sfdx-project.json`.
-   Prefer existing utilities, Custom Metadata, Custom Labels, permission sets,
    and declared package dependencies over new hardcoded configuration.
-   Use English for metadata labels, API names, Apex, and backend identifiers;
    use Translation Workbench for user-facing Norwegian text.
-   Use descriptive whole-word names: PascalCase for custom objects and fields,
    verb-first camelCase for Apex methods, and the established
    `<Namespace>_<ClassName><Suffix>` shape for Apex classes.
-   Name Apex tests after the class under test without an underscore before
    `Test`; name test methods after the business scenario or expected behaviour,
    not the method under test.
-   Keep code clean and readable: small cohesive methods, clear names, shallow
    control flow, explicit boundaries, and no speculative abstractions.
-   For new or materially changed Apex, use ApexDoc (`/** ... */`) for public
    classes, interfaces, enums, methods, constructors, public properties, and
    significant annotations. Include `@param`, `@return`, `@throws`, `@see`,
    `@since`, or `@deprecated` where applicable.
-   Keep triggers thin and delegate business logic to a handler or service. Make
    sharing, security, data ownership, error behaviour, and integration
    contracts explicit.

## Well-Architected review

For design changes, review the relevant dimensions:

-   **Trusted:** secure access, compliant handling of personal data, and
    reliable failure/recovery behaviour.
-   **Easy:** intentional scope, maintainable/readable code, appropriate
    automation, and an understandable user workflow.
-   **Adaptable:** resilient operations, separation of concerns,
    interoperability, and packageability.

The review should state the main tradeoff and the evidence used to support the
choice.

## Local validation

Run the narrowest relevant check first:

-   `npm test -- --runInBand` for LWC Jest tests.
-   `npm run prettier:check` for formatting.
-   `npm run prettier:write` only when formatting changes are intended.
-   `sf project deploy preview --source-dir force-app` only after the user
    confirms the exact target and preview action. A preview may access an org.
-   `sf project deploy start --source-dir force-app --target-org <alias>
--test-level RunLocalTests` only after the user confirms the exact target and
    deployment action. Never use a production target.
-   Inspect `bin/install-scratch.sh` before use. Do not run it, or any other
    script that creates or accesses an org, without the user's confirmation
    immediately before that operation. Never create or access production orgs.

A change is not complete until the relevant local checks pass or any
environmental limitation is reported clearly.

## Agent workflow

1. Inspect the nearest implementation, related tests, metadata, and applicable
   instructions before editing.
2. State the intended scope when a change crosses package or deployment
   boundaries.
3. Make the smallest focused change and preserve unrelated user work.
4. Validate with the narrowest executable check available.
5. Summarize files changed, validation performed, and any checks that could not
   run.

Ask for explicit confirmation before modifying read-only package directories,
creating or releasing a package version, or changing CI/CD and authentication
configuration. For org access, apply the per-operation confirmation rules
above; production remains prohibited.
