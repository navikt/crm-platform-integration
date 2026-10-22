---
applyTo: 'force-app/**/*.xml,force-app/**/*.flow-meta.xml,force-app/**/*.object-meta.xml,force-app/**/*.field-meta.xml'
---

# Salesforce metadata standards

For new or materially changed Salesforce metadata in the main package:

-   Confirm that the path belongs to `force-app/` and not a package-owned or reference-only directory before editing.
-   Preserve Salesforce source format, metadata type names, API versions, and existing public names unless the task includes an approved migration plan.
-   Use English for metadata and API identifiers. Use descriptive PascalCase for new custom objects and fields, with no unnecessary underscores beyond Salesforce-required suffixes.
-   Keep labels, descriptions, help text, permissions, and automation understandable to both administrators and developers. Translate user-facing text through the established translation pattern.
-   Prefer existing Custom Metadata, Custom Labels, permission sets, Named Credentials, and established package dependencies over hardcoded configuration.
-   For Flows and declarative automation, keep entry criteria explicit, avoid duplicated business rules, handle fault paths, and keep orchestration separate from reusable logic where practical.
-   Treat permission sets, sharing, field-level security, Experience Cloud access, and metadata visibility as security-sensitive. Require human review for access changes.
-   Before any command that accesses an org, ask the user to confirm the exact target and action for that operation. This includes deploy previews and validation workflows that connect to an org. Deployment, package creation, promotion, and org changes also require explicit confirmation. Production is always prohibited.
-   Review design changes against Salesforce Well-Architected: Trusted, Easy, and Adaptable. State important dependencies, failure behaviour, packageability, and rollback considerations.
-   Add or update focused tests for behaviour affected by metadata changes, and report when validation requires an authenticated Salesforce org.
