# Runbook: {change or operation}

## Purpose and scope

Describe the change, reason, affected feature/integration, and what this
procedure does not cover.

## Ownership and approvals

-   Implementing team/owner: {team or role}
-   Operational owner: {team or role}
-   Team Platforce approval/reference: {Issue, approval, or not applicable}
-   Planned execution window: {date/time or TBD}

Do not include personal contact details, credentials, tokens, or secrets.

## Preconditions

-   {Required deployment, package version, configuration, or dependency}
-   {Required approvals and access}
-   {Checks that must pass before execution}

## Metadata changes

List every metadata component that is renamed or deleted. Include API names,
not just display labels. Add rows as needed.

| Action               | Metadata type | Current API name | New API name  | Reason   |
| -------------------- | ------------- | ---------------- | ------------- | -------- |
| {Rename/Delete/None} | {type}        | {name}           | {name or N/A} | {reason} |

## Script

If a script is required, it must be committed to this repository and tested,
verified, reviewed, and approved before Team Platforce runs it.

-   Repository path: {path or N/A}
-   Revision/commit: {revision or TBD}
-   Test and verification evidence: {references or TBD}
-   Approval evidence: {reference or TBD}
-   Required inputs and expected outputs: {description; no secrets}

## Procedure

List steps in execution order. Identify the responsible role and target
environment for each step. Never include credentials or secret values.

| Step | Action   | Environment   | Responsible role | Status/evidence                 |
| ---- | -------- | ------------- | ---------------- | ------------------------------- |
| 1    | {action} | {environment} | {role}           | {planned or evidence reference} |

## Verification and cleanup

Record verification only after it has been performed. Do not treat a planned
step as completed.

-   SIT2 metadata cleanup: {verified/not applicable/pending; evidence reference}
-   Production metadata cleanup and verification: Team Platforce only
    {verified/not applicable/pending; approval and evidence reference}
-   Application or integration behaviour: {checks and evidence}
-   Audit/change record: {reference}

## Failure handling and rollback

Describe stop conditions, escalation path, recovery or rollback steps, and
conditions for resuming the procedure.
