---
applyTo: 'force-app/**/*.cls'
---

# Salesforce Apex standards

For new or materially changed Apex in the main package:

-   Follow the local rules in `force-app/AGENTS.md`, the additional
    `force-app/main/default/AGENTS.md` rules when applicable, and Nav Platforce
    naming conventions.
-   Use `with sharing` by default. Make any privileged sharing decision explicit in ApexDoc.
-   Keep classes cohesive, methods small, names descriptive, and control flow easy to follow. Prefer the simplest design that satisfies the requirement.
-   Keep triggers thin and delegate business logic to a handler or service.
-   Bulkify all SOQL and DML. Do not query or perform DML inside loops.
-   Avoid hardcoded IDs, URLs, credentials, package keys, and personal data. Use existing configuration, Custom Metadata, Custom Labels, Named Credentials, and test factories.
-   Protect `@AuraEnabled`, `@InvocableMethod`, REST, and callout boundaries with explicit validation, access checks, error handling, and documented platform behaviour.
-   Use ApexDoc for new or materially changed public classes, methods, constructors, properties, interfaces, enums, and significant annotations, following the official Salesforce ApexDoc standard: [Intro](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_doc_intro.htm), [Format](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_doc_format.htm), [Constructs](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_doc_constructs.htm), [Examples](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_doc_examples.htm).
    -   Start every ApexDoc comment with a one-sentence main-description summary before any block tag. `/** @param ... */` without a summary sentence is non-compliant.
    -   Do not use an `@description` tag; write the description as the summary sentence at the start of the ApexDoc comment.
    -   For classes/interfaces/enums, include `@author` (one tag per person), `@since`, and `@group`. List the file's original author first (its first-ever commit), followed by its top contributors ordered by each person's first commit on the file. Determine both from `git log --follow` on the file; never invent a name or date.
    -   Use `@since` at method/property level too when git history shows the element was added materially later than the class's own `@since` date. Skip it when the date would just repeat the class-level date.
    -   Document public properties individually (short one-line ApexDoc), not only through a constructor's `@param`.
    -   For `@AuraEnabled(cacheable=true)` methods, state the cache implication (e.g. that the calling LWC must call `refreshApex()` to invalidate stale data).
    -   For `@TestVisible` members, state the test-only rationale in one line.
    -   Use `@example` with `{@code ...}` only for genuinely reusable Apex-callable APIs (services, utilities) where a snippet clarifies usage. Skip it for LWC-facing `@AuraEnabled` controller methods invoked from JavaScript, since an Apex snippet would not reflect real usage.
    -   Do not add blanket `@SuppressWarnings('PMD')` to hide static-analysis findings. If a specific rule must be suppressed, name the exact rule (e.g. `@SuppressWarnings('PMD.MethodNamingConventions')`) and document why in the ApexDoc.
-   Name tests after business scenarios and expected behaviour. Do not add a `test` prefix to test methods.
-   Always qualify Apex test API usage with the Salesforce namespace: use `System.Assert.*` and `System.Test.*` in Apex tests. Never use bare `Assert` or unqualified `Test` calls.
-   Include at least one `System.runAs(minimumAccessUser)` in Apex test classes when the behaviour under test does not require elevated permissions. Use the minimum-access profile (`Profile.Name = 'Minimum Access - Salesforce'`) unless the scenario genuinely requires stronger rights.
-   Add or update a focused behavioural test before implementation when an executable test seam exists. Report an authenticated-org blocker for Apex tests instead of claiming a green result.
-   Review design changes against Salesforce Well-Architected: Trusted, Easy, and Adaptable. Record important tradeoffs and preserve deployed public contracts.
