# Contributing

This repository contains a Nav-owned Salesforce package. Contributions from
Nav colleagues and external contributors follow the same technical standards,
but have different coordination and access boundaries. This guide does not
grant access to Nav systems, Salesforce orgs, or internal documentation.

## Nav colleagues

1. Create or update a [GitHub Issue](https://github.com/navikt/crm-platform-integration/issues/new/choose)
   with the need, scope, and acceptance criteria.
2. Coordinate package ownership, architecture, and any operational work with
   Team Platforce. Follow current Nav and Platforce development standards.
3. Before any Salesforce org operation, obtain approval for the exact
   non-production target and action. Production access is prohibited for AI
   agents; never use credentials or approvals from another operation.
4. Open a pull request using the repository template and request review from
   the owners listed in [CODEOWNERS](.github/CODEOWNERS).

Use approved Nav channels for internal coordination. Do not put credentials,
org details, personal data, or other internal-only information in public Issues
or pull requests.

## External contributors

1. Open an Issue describing the proposed change and wait for maintainers to
   confirm that the scope is suitable before starting substantial work.
2. Do not access or request Nav Salesforce orgs, credentials, package keys,
   internal systems, or non-public documentation. Do not run commands or
   scripts that connect to a Salesforce org.
3. Use synthetic data only. Keep changes focused on this repository and do not
   modify separately owned package directories or dependencies without
   maintainer approval.
4. Submit a pull request using the repository template. Maintainers review
   contributions against package ownership, security, compatibility, and the
   project roadmap. An Issue or pull request is not a commitment to accept or
   merge the change.

## Shared development expectations

- Read [AGENTS.md](AGENTS.md), [CONTEXT.md](CONTEXT.md), and the relevant
  instructions before changing Salesforce code or metadata.
- Preserve existing package boundaries and public contracts. Ask maintainers
  before changing dependencies, CI/authentication, deployment workflows, or
  package-owned content.
- For behavior changes, add focused tests and use a red-green-refactor loop
  where the local environment supports it.
- Run relevant local checks and report the exact commands and results. For
  example:

    ```bash
    npm ci
    npm run prettier:check
    npm run test:scratch-org
    ```

- Clearly report checks that require an org and do not describe blocked or
  unrun checks as passing. Human-operated org work requires separate approval;
  production is never an agent target.
- Update related documentation. Add or update a [runbook](runbooks/README.md)
  when a change requires manual steps or Team Platforce action.
- Do not include secrets, credentials, package installation keys, real personal
  data, or environment-specific access details in code, fixtures, Issues, or
  pull requests.

See the [development workflow](docs/arbeidsflyt-og-dokumentasjon.md) for the
repository's Issue-to-implementation process and the
[pull request template](.github/PULL_REQUEST_TEMPLATE.md) for required review
evidence.
