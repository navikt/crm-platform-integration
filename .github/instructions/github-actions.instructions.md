---
applyTo: '.github/workflows/**/*.yml'
---

# GitHub Actions standards

For new or materially changed workflows:

-   Preserve the existing Nav reusable-workflow model unless the task explicitly requires a different design.
-   Pin third-party actions and reusable workflows to immutable commit SHAs where the owning team supports it. Treat mutable branch or tag references as a supply-chain risk and record any approved exception.
-   Grant the minimum required `permissions` at workflow and job level. Keep pull-request workflows read-only unless a specific write operation is required and approved.
-   Keep deployment, package creation, package promotion, authentication, and environment changes behind explicit human approval and protected GitHub environments. Never deploy to or access production.
-   Keep validation steps visible and fail-closed. Do not remove or weaken tests, formatting, security scanning, deployment previews, or approval gates to make a workflow pass.
-   Do not expose secrets, package installation keys, Salesforce credentials, personal data, tokens, request bodies, or generated authentication output in logs or artifacts.
-   Use path filters and caching only when they preserve coverage and do not allow relevant Salesforce metadata or tests to bypass validation.
-   For reusable workflows, document the external owner and the validation responsibility. If the implementation is opaque from this repository, report that as a validation limitation.
-   Review workflow changes against Salesforce Well-Architected: Trusted supply chain and access, Easy-to-understand validation, and Adaptable/reproducible delivery.
