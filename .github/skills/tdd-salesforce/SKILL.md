---
name: tdd-salesforce
description: Test-driven development for Salesforce Apex and LWC. Use for new behaviour, bug fixes, regression tests, red-green-refactor, or when an agent is asked to work test-first.
---

# TDD for Salesforce

Use one vertical slice at a time. A test is a behavioural specification at a public seam, not a check of private implementation details.

## Workflow

1. State the requested behaviour as an observable outcome.
2. Identify the seam:
    - LWC public behaviour: rendered DOM, user event, wire response, Apex call or error state.
    - Apex public behaviour: `@AuraEnabled` method, public service/controller method, trigger outcome, or domain-level result.
    - Metadata behaviour: deploy-preview or scratch-org validation outcome.
3. Read the nearest existing test and test-data factory before adding a fixture.
4. Write one focused failing test with a descriptive behaviour name.
5. Run the narrowest command that can execute it:
    - LWC: `npm test -- --runInBand <focused-test>` or the repository's Jest equivalent.
    - Apex: the smallest authenticated Salesforce test run that reaches the seam.
    - Metadata: `sf project deploy preview --source-dir force-app` when no executable unit seam exists.
6. Implement only enough production code to make the test pass.
7. Run the same focused check again and record the result.
8. Refactor only after green, preserving the test's behavioural meaning.
9. Run the broader relevant check before completion.

## Salesforce constraints

-   Apex tests must be bulk-safe and use an existing repository test-data factory where applicable.
-   Always use the fully qualified Salesforce namespaces in Apex tests: `System.Assert.*` for assertions and `System.Test.*` for lifecycle calls such as `System.Test.startTest()` and `System.Test.stopTest()`. Never use bare `Assert` or unqualified `Test` calls.
-   Apex test classes should include at least one `System.runAs(minimumAccessUser)` call when the behaviour under test does not require elevated access. Create the user from the minimum-access profile (`Profile.Name = 'Minimum Access - Salesforce'`) unless the scenario truly requires a stronger profile.
-   Do not use real personal data, hardcoded org IDs, or package-owned source in test fixtures.
-   Prefer `System.Test.startTest()` and `System.Test.stopTest()` around the operation under test.
-   Test both successful and error outcomes for user-facing or integration behaviour.
-   Use `HttpCalloutMock` for callouts and assert the observable contract, not internal implementation.
-   If an Apex red test cannot run because no authenticated org is available, stop at the written test and report the exact blocked command. Do not simulate a green result.
-   Name new Apex test classes and methods according to Nav Platforce conventions: the class is `<ClassBeingTested>Test`, and the method describes the business scenario or expected behaviour without a `test` prefix.
-   When the slice adds or changes a public Apex contract, document the contract with ApexDoc, including parameter, return, exception, sharing, and annotation implications where relevant.

## Test quality

A good test is independent, deterministic, readable as a requirement, and resilient to refactoring. Avoid tests that inspect private state, duplicate the implementation to calculate the expected value, share mutable state, or assert only that code did not throw.

## Completion gate

The slice is complete only when the focused test is green, the relevant broader check has run, or the environmental blocker is explicitly recorded. The final report must name the seam, the red check, the green check, and any check that could not run.
