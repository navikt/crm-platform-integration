# Project Context: crm-platform-integration

## Package

`crm-platform-integration` is a Salesforce DX Unlocked Package. Its declared
package source is `force-app/`, with package name, version, and dependencies
defined in `sfdx-project.json`. The repository also lists `src-temp` as a
default package directory; it is reference-only under
`.copilot/reference-only.instructions.md`.

The package receives and processes JSON payloads, including changes from a
Kafka CDC pipeline. It also contains feature- and integration-specific
Salesforce code and metadata. This context describes this package and repository,
not every product or package that may use its data.

## Repository shape

-   `force-app/` contains the `crm-platform-integration` package source, grouped
    into feature and integration areas. Follow the existing area layout; do not
    move or rename existing code without an approved migration.
-   `force-app/main/default/` contains shared Salesforce metadata and code, with
    directory-specific guidance in `force-app/main/default/AGENTS.md`.
-   `sfdx-project.json` declares package directories and dependencies, including
    `platform-data-model`, `custom-metadata-dao`, `custom-permission-helper`,
    `feature-toggle`, `crm-platform-base`, `crm-shared-flowComponents`, and
    `crm-henvendelse-base`. Treat the manifest as the source of truth.
-   Directories identified as reference-only in
    `.copilot/reference-only.instructions.md` may be read for context but must
    not be changed without explicit user approval.
-   `.github/instructions/` and `.github/skills/` contain repository-specific
    agent guidance and workflows. `docs/` contains technical documentation;
    `runbooks/` contains operational procedures.

## Integration and feature map

This map is an orientation aid based on the current `force-app/` directories
and their visible classes, metadata, and local documentation. It describes
where to start looking, not a full API contract or a guarantee that every
directory is an external integration. Read the implementation and relevant
Custom Metadata before changing behaviour.

| Area                      | Location                       | Current scope indicated by repository                                                                      |
| ------------------------- | ------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| GraphQL query support     | `force-app/GraphQLQuery/`      | GraphQL query, operation, field, argument, and value model classes.                                        |
| Altinn                    | `force-app/altinn/`            | Altinn 2/3 callout services, request/response helpers, and token-cache adapters.                           |
| CV                        | `force-app/cv/`                | CV service and CV data wrapper classes.                                                                    |
| EREG handler              | `force-app/ereg-handler/`      | Kafka EREG unit (`Enhet`) model, filtering, and message handling.                                          |
| Felles kodeverk           | `force-app/felles-kodeverk/`   | Fetching and handling common code values, including callout and asynchronous service classes.              |
| KRP                       | `force-app/krp/`               | KRP callout service, person service, and response wrappers.                                                |
| KRR                       | `force-app/krr-integration/`   | KRR callout and Maskinporten services. The local README describes routing through the Digdir KRR proxy.    |
| Shared package core       | `force-app/main/default/`      | Shared metadata and Kafka message ingestion, asynchronous processing, handlers, and message services.      |
| Person merge              | `force-app/mergePerson/`       | Person merge and batch-processing logic.                                                                   |
| Monitoring                | `force-app/monitoring/`        | Scheduled monitoring for FSS integration.                                                                  |
| NOM                       | `force-app/nom/`               | NOM service and synchronization for organizational units and resources, with related helpers and wrappers. |
| NORG                      | `force-app/norg/`              | NORG service, NAV unit and contact-information wrappers, and code-set utilities.                           |
| PDL Apex types            | `force-app/pdl-apexTypes/`     | Apex data types representing PDL response structures.                                                      |
| PDL API                   | `force-app/pdl-api/`           | PDL query, service, response, and API support classes.                                                     |
| PDL handlers              | `force-app/pdl-handler/`       | Kafka handlers for PDL person and related message types.                                                   |
| PDL helpers               | `force-app/pdl-helpers/`       | PDL-related helper classes. Check the local classes and metadata for the exact responsibilities.           |
| Representation / fullmakt | `force-app/repr/`              | Fullmakt service and related configuration.                                                                |
| Scratch-org metadata      | `force-app/scratch-org/`       | Salesforce applications, flexipages, profiles, and tabs used in the package source.                        |
| Skjerming handlers        | `force-app/skjerming-handler/` | Kafka handlers and scheduled jobs related to skjerming.                                                    |
| SMS                       | `force-app/sms/`               | SMS callout, handler, receiver, and queueable services.                                                    |
| TPS                       | `force-app/tps/`               | TPS callout and person service, with related wrappers.                                                     |
| WebSak                    | `force-app/websak/`            | WebSak file service.                                                                                       |

The package root [`README.md`](README.md) is the primary reference for Kafka
message ingestion and handling. For operational Kodeverk details, see
[`runbooks/kodeverk/`](runbooks/kodeverk/). For KRR routing context, see
[`force-app/krr-integration/README.md`](force-app/krr-integration/README.md).

## Domain and integration language

-   **Kafka message:** A JSON payload received by this package and represented by
    a `KafkaMessage__c` record.
-   **Topic:** The message topic used to select the configured message handler.
-   **Handler binding:** Custom Metadata configuration connecting an async
    request type or Kafka topic to an Apex handler.
-   **Async request:** A request record used by the asynchronous processing
    framework from the `crm-platform-base` dependency to schedule message
    processing.
-   **Kafka consumer:** The synchronous event-handling pattern uses a platform
    event and the `IKafkaMessageConsumer` contract. Failed events can be retained
    as `KafkaMessage__c` records for error handling.
-   **Felles kodeverk:** `KodeverkCalloutService` supports fetching code values
    and, where applicable, storing them as `Common_Code__c` records. Operational
    details are in `runbooks/kodeverk/`.

The README and implementation are the sources of truth for exact payload
contracts, handler behaviour, topic configuration, retry semantics, and
integration-specific rules. Do not infer external API contracts from folder
names alone.

Use English for Apex, metadata, API, and backend identifiers. Use the
repository's established Salesforce translation patterns for user-facing
Norwegian text.

## Architectural boundaries

-   Keep changes within the `crm-platform-integration` package unless the
    request explicitly targets another area.
-   Treat separately owned package directories and dependencies as boundaries.
    Read their source for context, but do not modify them without explicit user
    approval.
-   Preserve deployed metadata names and public Apex contracts unless an approved
    migration explicitly changes them.
-   Prefer existing package utilities, Custom Metadata bindings, Labels,
    Named Credentials, permission sets, and declared dependencies before adding
    new abstractions or configuration.
-   Treat access control, personal data, authentication, callouts, metadata
    visibility, and org operations as sensitive work requiring careful review
    and any applicable user approval.
-   For new or changed design, assess Salesforce Well-Architected:
    **Trusted** (secure, compliant, reliable), **Easy** (intentional,
    understandable, maintainable), and **Adaptable** (resilient, interoperable,
    separated, and packageable).

## Verification vocabulary and org safety

-   **Local:** Formatting, static checks, and LWC Jest tests that do not access a
    Salesforce org.
-   **Org-dependent:** Apex tests, metadata validation or retrieval, deployments,
    package operations, and scripts that connect to Salesforce.
-   **Red-green-refactor:** Write a focused behavioural test, observe it fail,
    implement the smallest change, observe it pass, then refactor and run
    relevant broader validation.
-   **User-confirmed org operation:** Before every command that accesses a
    Salesforce org or environment, obtain the user's confirmation for the exact
    target and action. Do not infer permission from an authenticated or default
    alias, previous approval, or a repository script.
-   **Production:** Always prohibited. Never connect to, query, retrieve from,
    test against, or deploy to a production org, even if requested.

Never report an org-dependent check as successful unless its command completed
successfully. If the target or action has not been confirmed, do not run the
command and report the prerequisite.

## AI and change governance

-   General Nav guidance may come from user scope or an approved Nav collection;
    Salesforce package and repository-specific guidance lives in this repository.
-   Local build and test commands must not depend on an external documentation
    collection being available.
-   GitHub Issues are the system of record for work items. Create user stories
    with `.github/ISSUE_TEMPLATE/user-story.yml`. Short feature specifications
    belong in `.github/specs/`.
-   Follow `docs/arbeidsflyt-og-dokumentasjon.md` for how Issues,
    specifications, implementation, validation, and documentation relate.
-   Store architecture decision records under `docs/adr/` using
    `docs/adr/template.md`. Store cross-cutting technical documentation under
    `docs/architecture/`, domain guidance under `docs/domain/`, surface
    contracts under `docs/surfaces/`, and integration documentation under
    `docs/integrations/`.
-   Keep this file for stable package context and shared verification vocabulary.
    Put implementation rules in `AGENTS.md` or the applicable
    `.github/instructions/`; put consequential architecture decisions in ADRs.
-   Public repository documentation must not contain personal names, national
    identity numbers, credentials, tokens, secrets, or environment-specific
    access details.
