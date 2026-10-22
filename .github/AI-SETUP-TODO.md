# AI setup backlog

Remaining setup work:

## Human-owned governance follow-up

-   Review GitHub environment protections, workflow permissions, and deployment
    approval gates against the production policy. Do not change or run a
    deployment workflow without the required human approval.
-   Create and validate integration contract documentation for the highest-risk
    integrations, using verified owners and source material.
-   Establish a small, repeatable Copilot validation checklist for correct
    instruction selection, safe org-operation handling, and refusal to access
    production.

## Conventions to retain

-   Apex tests are colocated with their feature or integration under
    `force-app/`. Do not create `force-app/tests/classes/` unless the project
    intentionally adopts a new test layout.
