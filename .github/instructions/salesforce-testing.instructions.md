---
applyTo: 'force-app/**/*Test.cls,force-app/**/__tests__/**/*.js'
---

# Salesforce testing standards

For new or materially changed Apex and LWC tests:

-   Follow `.github/skills/tdd-salesforce/SKILL.md` and identify the public behavioural seam before writing the test.
-   Write one focused test for one observable behaviour, then run it red before implementing the smallest change.
-   Always use the fully qualified Salesforce namespaces in Apex tests: `System.Assert.*` for assertions and `System.Test.*` for lifecycle calls such as `System.Test.startTest()` and `System.Test.stopTest()`. Never use bare `Assert` or unqualified `Test` calls.
-   Apex test classes should include at least one `System.runAs(minimumAccessUser)` call when the behaviour under test does not require elevated access. Create the user from the minimum-access profile (`Profile.Name = 'Minimum Access - Salesforce'`) unless the scenario truly requires a stronger profile.
-   Name Apex test methods after the business scenario and expected behaviour, using a readable `given_When_Then` or `should_When` shape without a `test` prefix. Use descriptive Jest test names as well.
-   Prefer assertions against public outcomes: returned values, persisted records, emitted events, rendered DOM, user-visible errors, callout requests, or permission outcomes.
-   Avoid private-state assertions, implementation-coupled mocks, tautological expectations, shared mutable state, and tests that only prove that code did not throw.
-   Keep tests deterministic and isolated. Use `System.Test.startTest()`/`System.Test.stopTest()` around the operation under test and existing test-data factories where applicable.
-   Do not use real personal data, hardcoded Salesforce IDs, package keys, credentials, or org-specific URLs in fixtures.
-   Test both success and relevant error paths, including access denial and empty or missing data where the contract exposes them.
-   For callouts, use `HttpCalloutMock` and assert the integration contract without making real network calls.
-   For LWC, test user-visible DOM and interaction, wire/Apex outcomes, loading/empty/error states, and relevant accessibility behaviour.
-   Before running any test command that accesses a Salesforce org, ask the user to confirm the exact target and test action for that run. Production is always prohibited.
-   If an Apex test requires an org and the target/action has not been confirmed, report the exact blocked command and do not claim the test is green.
-   Use ApexDoc for new or materially changed test classes and test methods, following the same standard as production Apex (see `.github/instructions/salesforce-apex.instructions.md`).
    -   Use `@author` for the responsible human owner or verified human contributors. Do not list an AI tool as an author; record AI assistance in the relevant GitHub Issue, pull request, or work log when traceability is required.
    -   Give the test class a class-level ApexDoc block with a one-sentence summary, `@author` (original file author first, then top contributors ordered by each person's first commit on the file, from `git log --follow`), `@since`, and `@group`.
    -   Give each test method a one-sentence ApexDoc summary of the scenario under test, plus `@since` showing when that specific test method was added (from `git log -S"methodName"` on the file), so the history of test coverage growth stays visible. Always include `@since` on test methods, even when it matches the class-level `@since`. Never invent a date; if history cannot be determined reliably, state that explicitly instead of guessing.
    -   Do not add `@param`/`@return` to test methods (they take no meaningful parameters and return void).
