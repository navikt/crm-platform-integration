---
applyTo: 'force-app/**/*.js,force-app/**/*.html,force-app/**/*.css'
---

# Salesforce LWC standards

For new or materially changed Lightning Web Components in the main package:

-   Follow the local rules in the root `AGENTS.md` and
    `force-app/AGENTS.md`. Also follow `force-app/main/default/AGENTS.md` when
    working in that directory, and the relevant Nav Platforce documentation.
-   Keep components focused and readable. Prefer clear event flow, explicit state transitions, and small helper methods over clever or deeply nested logic.
-   Use Salesforce base components and existing repository utilities before creating custom equivalents.
-   Treat data from Apex, wires, URL state, files, and user input as untrusted. Validate it at the component boundary and handle loading, empty, success, and error states explicitly.
-   Keep Apex calls and wire adapters observable in tests. Do not hide important behaviour behind implementation-only helpers.
-   Write Jest tests for user-visible behaviour: rendered content, user interaction, Apex/wire outcomes, error states, and relevant accessibility expectations. Use existing mocks and test setup.
-   Use descriptive scenario-based test names and keep each test independent and deterministic.
-   Preserve semantic HTML, keyboard access, labels, focus behaviour, and meaningful error messages. Do not use manual DOM manipulation when a reactive template can express the behaviour.
-   Avoid logging personal data, tokens, request bodies, or file contents. Use the established error-handling and logging patterns.
-   Run the narrowest focused Jest test after each change, then run the broader relevant test and formatting checks.
-   If a change crosses an authenticated Salesforce-org boundary, report that blocker explicitly; do not claim Apex or deployment validation passed without a completed command.
