# Scratch-org command reference

Use this page when you know which operation you need. For prerequisites,
approval boundaries, and the normal setup flow, start with the
[scratch-org setup guide](scratch-org.md).

## Choose an entry point

All commands assume the repository root as the working directory. The Node/npm
launcher selects Bash on macOS/Linux and PowerShell 7 on Windows.

<details>
<summary>macOS and Linux</summary>

```bash
bash bin/create-scratch-org.sh --help
npm run scratch-org -- --help
```

Use Bash flags such as `--dry-run` and `--post-steps-only`. Running the PowerShell
engine directly on macOS requires PowerShell 7:

```bash
pwsh -NoLogo -NoProfile -File ./bin/create-scratch-org.ps1 -Help
```

</details>

<details>
<summary>Windows PowerShell 7</summary>

```powershell
.\bin\create-scratch-org.ps1 -Help
npm run scratch-org '--' -Help
```

Use PowerShell parameter names such as `-DryRun` and `-PostStepsOnly`. Quote
the npm separator as `'--'`; otherwise PowerShell may consume it before npm
receives the arguments.

</details>

<details>
<summary>Windows CMD</summary>

```cmd
bin\create-scratch-org.bat -Help
npm run scratch-org -- -Help
```

The batch launcher forwards parameters and the exit code to PowerShell 7.
Use PowerShell parameter names such as `-DryRun` and `-PostStepsOnly`.

</details>

The launcher normalizes help flags only. Other flags are passed to the selected
engine and are not translated between Bash and PowerShell.

## Common workflows

These examples show intent, not approval to access an org. Replace placeholders
with a confirmed, non-production target and approved values.

| Task                                       | Bash                                                                | PowerShell 7                                                       |
| ------------------------------------------ | ------------------------------------------------------------------- | ------------------------------------------------------------------ |
| Preview available commands                 | `npm run scratch-org -- --help`                                     | `npm run scratch-org '--' -Help`                                   |
| Check dependencies                         | `npm run scratch-org -- --check-dependencies`                       | `npm run scratch-org '--' -CheckDependencies`                      |
| Preview setup                              | `npm run scratch-org -- --dry-run`                                  | `npm run scratch-org '--' -DryRun`                                 |
| Run configured setup                       | `npm run scratch-org`                                               | `npm run scratch-org`                                              |
| Run selected post-steps on an existing org | `npm run scratch-org -- --post-steps-only --post-steps deploy,data` | `npm run scratch-org '--' -PostStepsOnly -PostSteps 'deploy,data'` |
| Full redeploy to an existing org           | `npm run scratch-org -- --redeploy`                                 | `npm run scratch-org '--' -Redeploy`                               |
| Plan package changes                       | `npm run scratch-org -- --package-plan`                             | `npm run scratch-org '--' -PackagePlan`                            |
| Update packages only                       | `npm run scratch-org -- --update-packages`                          | `npm run scratch-org '--' -UpdatePackages`                         |
| Delete the configured scratch org          | `npm run scratch-org -- --delete-org-only`                          | `npm run scratch-org '--' -DeleteOrgOnly`                          |

`--dry-run` / `-DryRun` is not offline: dependency, package-version, or pool
reads can contact Salesforce. A full run can fetch or create an org, install
packages, and run configured post-steps. The checked-in config uses the `dev`
pool and does not fall back to creating an org when the pool is empty.

## More examples

All Salesforce examples below require prior approval for the exact
non-production target and operation. Do not replace placeholders with a
production org.

<details>
<summary>macOS and Linux</summary>

```bash
# Preview the generated configuration; this does not write a file.
bash bin/create-scratch-org.sh --init-config --dry-run

# Review recursive dependency requirements and write a report.
bash bin/create-scratch-org.sh --check-dependencies --dependency-report dependency-review.md

# Apply fixable manifest dependency/order changes after reviewing the report.
bash bin/create-scratch-org.sh --apply-dependencies

# Preview newer package versions, then apply them in a separate reviewed step.
bash bin/create-scratch-org.sh --check-versions
bash bin/create-scratch-org.sh --apply-project-versions

# Run Apex coverage checks on an approved existing non-production org.
bash bin/create-scratch-org.sh --coverage-check --coverage-skip-install --coverage-skip-deploy --alias <approved-non-production-alias>
```

</details>

<details>
<summary>Windows PowerShell 7</summary>

```powershell
# Preview the generated configuration; this does not write a file.
.\bin\create-scratch-org.ps1 -InitConfig -DryRun

# Review recursive dependency requirements and write a report.
.\bin\create-scratch-org.ps1 -CheckDependencies -DependencyReport dependency-review.md

# Apply fixable manifest dependency/order changes after reviewing the report.
.\bin\create-scratch-org.ps1 -ApplyDependencies

# Preview newer package versions, then apply them in a separate reviewed step.
.\bin\create-scratch-org.ps1 -CheckVersions
.\bin\create-scratch-org.ps1 -ApplyProjectVersions

# Run Apex coverage checks on an approved existing non-production org.
.\bin\create-scratch-org.ps1 -CoverageCheck -CoverageSkipInstall -CoverageSkipDeploy -OrgAlias <approved-non-production-alias>
```

</details>

`--apply-dependencies` / `-ApplyDependencies` writes the manifest and a backup
after Salesforce metadata has been read. Version apply also reads Salesforce
package versions before writing the manifest. Coverage still runs Apex tests and
queries the org when install and deploy are skipped.

A custom post-step is configured in `sf-project.config.json`; it runs the
configured executable from the project root. Review this as executable code:

```json
{
    "customPostSteps": [
        {
            "name": "runtime-check",
            "label": "Show Node version",
            "executable": "node",
            "arguments": ["--version"]
        }
    ],
    "postSteps": ["deploy", "runtime-check"]
}
```

Keep any existing project settings when adding this block. Use the
`--post-steps-only --post-steps runtime-check` mode (or PowerShell
`-PostStepsOnly -PostSteps runtime-check`) only for an approved existing org;
even custom commands may have side effects.

## Option reference

`<value>` means replace the placeholder. Use one main mode at a time; some modes
are mutually exclusive.

### Target and configuration

| Bash                             | PowerShell 7                         | Purpose                                                                             |
| -------------------------------- | ------------------------------------ | ----------------------------------------------------------------------------------- |
| `-a`, `--alias <alias>`          | `-OrgAlias <alias>` (`-Alias` alias) | Select the target alias.                                                            |
| `-d`, `--duration-days <1..30>`  | `-DurationDays <1..30>`              | Scratch-org lifetime; default is 14 days.                                           |
| `-f`, `--definition-file <file>` | `-DefinitionFile <file>`             | Scratch-org definition file.                                                        |
| `-p`, `--project-file <file>`    | `-ProjectFile <file>`                | Salesforce DX project manifest; default is `sfdx-project.json`.                     |
| `--config <file>`                | `-ConfigFile <file>`                 | Use a specific `sf-project.config.json`.                                            |
| `--no-config`                    | `-NoConfig`                          | Ignore the project config file.                                                     |
| `--init-config`                  | `-InitConfig`                        | Write the effective settings to the config file and exit.                           |
| `--force`                        | `-Force`                             | Allow `--init-config` to update an existing config while preserving unmanaged keys. |

### Org and post-steps

| Bash                                                      | PowerShell 7              | Purpose                                                                                      |
| --------------------------------------------------------- | ------------------------- | -------------------------------------------------------------------------------------------- |
| `--use-pool`                                              | `-UsePool`                | Fetch a scratch org from the configured `sfp` pool.                                          |
| `--pool-tag <tag>`                                        | `-PoolTag <tag>`          | Override the pool tag.                                                                       |
| `--pool-devhub <alias>`                                   | `-PoolDevHub <alias>`     | Override the pool Dev Hub.                                                                   |
| No flag; `FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY=false` | `-NoFallbackToCreate`     | Stop if the pool is empty instead of creating an org.                                        |
| `--post-steps-only`                                       | `-PostStepsOnly`          | Use an existing org; skip org acquisition and normal package installation.                   |
| `-s`, `--post-steps <list>`                               | `-PostSteps <list>`       | Select `deploy`, `permsets`, `data`, `community`, configured custom steps, `all`, or `none`. |
| `--redeploy`                                              | `-Redeploy`               | Shortcut for post-steps-only deploy with full source tracking reset.                         |
| `--full-deploy`                                           | `-FullDeploy`             | Delete local source tracking before deploy so all source is deployed.                        |
| `--skip-org`                                              | `-SkipOrg`                | Skip org creation/deletion/fetch; other selected work may still access an org.               |
| `--skip-packages`                                         | `-SkipPackages`           | Skip normal manifest package installation.                                                   |
| `--delete-org-only`                                       | `-DeleteOrgOnly`          | Delete the selected scratch org and exit.                                                    |
| `--permission-sets <names>`                               | `-PermissionSets <names>` | Override configured permission sets.                                                         |
| `--dummy-data-plan <file>`                                | `-DummyDataPlan <file>`   | Override the data import plan.                                                               |
| `-c`, `--community-name <name>`                           | `-CommunityName <name>`   | Override the community name.                                                                 |

The standard post-steps are `deploy`, `permsets`, `data`, and `community`.
`postSteps` controls which run. Missing optional settings cause the related step
to be skipped with a warning. Configured custom steps execute their configured
program and arguments from the project root; review them as code execution.

### Packages and dependency sources

| Bash                              | PowerShell 7                  | Purpose                                                                                                                                     |
| --------------------------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `--update-packages`               | `-UpdatePackages`             | Install missing or lower-than-target packages without creating an org.                                                                      |
| `--install-latest`                | `-InstallLatest`              | Select the latest released package versions.                                                                                                |
| `--package-plan`                  | `-PackagePlan`                | Report package changes without installing. Reads org/package state.                                                                         |
| `--skip-version-check`            | `-SkipVersionCheck`           | Suppress newer-release warnings; does not disable dependency preflight.                                                                     |
| `--check-dependencies`            | `-CheckDependencies`          | Check recursive package requirements and write a dependency report. Reads Salesforce package metadata.                                      |
| `--apply-dependencies`            | `-ApplyDependencies`          | Apply fixable dependency declarations/order to the manifest and create a backup. Reads Salesforce package metadata; does not mutate an org. |
| `--dependency-report <file.md>`   | `-DependencyReport <file.md>` | Override the Markdown report path; an HTML report is written beside it.                                                                     |
| `--check-versions`                | `-CheckVersions`              | Preview newer versions for manifest dependencies.                                                                                           |
| `--apply-project-versions`        | `-ApplyProjectVersions`       | Update manifest version constraints and create a backup; does not install packages.                                                         |
| `--refresh-dependency-sources`    | `-RefreshDependencySources`   | Clear and retrieve configured dependency source directories. Can change local files and access Salesforce.                                  |
| `--clear-dependency-sources-only` | `-ClearDependencySourcesOnly` | Remove contents of configured dependency directories and exit. This is a local destructive operation.                                       |

Dependency preflight compares numeric versions against transitive minimum
requirements. A selected version above a minimum satisfies it, and the checker
inspects that selected version's dependency graph. A selected version below a
minimum blocks the check and is not automatically downgraded or replaced.
Missing metadata fails closed. Version checks, package plans, and dependency
preflight are different checks; passing one does not prove runtime compatibility
or package installability.

### Coverage

| Bash                              | PowerShell 7                       | Purpose                                                                            |
| --------------------------------- | ---------------------------------- | ---------------------------------------------------------------------------------- |
| `--coverage-check`                | `-CoverageCheck`                   | Run Apex tests and check aggregate coverage on an existing org.                    |
| `--coverage-package-id <04t...>`  | `-CoveragePackageId <04t...>`      | Optionally install the specified package version first. Use an actual approved ID. |
| `--coverage-minimum <0..100>`     | `-MinimumCoverage <0..100>`        | Required threshold; default is 75%.                                                |
| `--coverage-test-class <name>`    | `-CoverageTestClass <name>`        | Run one test class; otherwise run all tests.                                       |
| `--coverage-class-pattern <LIKE>` | `-CoverageClassNamePattern <LIKE>` | Filter classes included in the coverage query; default is `%`.                     |
| `--coverage-run-all`              | `-CoverageRunAll`                  | Run all tests even when a test class is configured.                                |
| `--coverage-skip-install`         | `-CoverageSkipInstall`             | Skip the optional coverage package install.                                        |
| `--coverage-skip-deploy`          | `-CoverageSkipDeploy`              | Skip deploying `force-app`; the tests and query still access the org.              |

Coverage checks are org-dependent. Unless skipped, the mode can install a
package and deploy metadata before running tests.

### Output and Bash-only options

| Bash                           | PowerShell 7  | Purpose                                                                     |
| ------------------------------ | ------------- | --------------------------------------------------------------------------- |
| `--dry-run`                    | `-DryRun`     | Print planned mutations; does not prevent read-only Salesforce access.      |
| `--self-check`                 | `-SelfCheck`  | Check required tools, authentication/configuration, and package resolution. |
| `--verbose`                    | `-Verbose`    | Show more successful CLI output.                                            |
| `--color`                      | `-Color`      | Force colored output.                                                       |
| `--no-color`                   | `-NoColor`    | Disable colored output.                                                     |
| `-h`, `--help`                 | `-Help`       | Show help without setup.                                                    |
| `--keychain-service <service>` | Not supported | Bash on macOS: select a Keychain service for the package install key.       |
| `--keychain-account <account>` | Not supported | Bash on macOS: limit Keychain lookup to an account.                         |

## Configuration

Settings use this precedence: command-line option, environment variable,
`sf-project.config.json`, then script default. The config is resolved beside the
project manifest unless `--config` / `-ConfigFile` or `SF_PROJECT_CONFIG` is set.
Relative paths are resolved from the project root.

The supported config groups are:

| Config key                                                                                                          | Controls                                                                             |
| ------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `defaultOrgAlias`, `scratchDefinition`, `scratchDurationDays`                                                       | Target alias and scratch-org definition/lifetime.                                    |
| `permissionSets`, `dummyDataPlan`, `communityName`, `postSteps`                                                     | Built-in post-step inputs and selection.                                             |
| `customPostSteps`                                                                                                   | Named executable, arguments, and optional label for custom post-steps.               |
| `pool.use`, `pool.tag`, `pool.devHub`, `pool.fallbackToCreate`                                                      | Pool selection and empty-pool behavior.                                              |
| `packageInstallKeyEnvironmentVariable`                                                                              | Environment variable name used to read package install keys.                         |
| `dummyUsers.file`, `dummyUsers.profileName`, `dummyUsers.profileAssignments`, `dummyUsers.permissionSetAssignments` | Optional profile and permission assignments for users in the configured data import. |
| `coverage.minimumPercent`, `coverage.testClass`, `coverage.classNamePattern`                                        | Coverage-check defaults.                                                             |
| `dependencySourcePolicy.preserveRootFiles`, `dependencySourcePolicy.requireLocalDirectories`                        | Local dependency source cleanup rules.                                               |

`commandTimeouts` is currently accepted by config validation but is not applied
to external command execution. Do not rely on it to stop a slow CLI command.

Example of a small project config (merge settings into the existing file rather
than replacing project-specific settings):

```json
{
    "schemaVersion": 1,
    "scratchDefinition": "config/project-scratch-def.json",
    "scratchDurationDays": 14,
    "permissionSets": [],
    "dummyDataPlan": null,
    "communityName": null,
    "postSteps": ["deploy"],
    "pool": {
        "use": true,
        "tag": "dev",
        "fallbackToCreate": false
    },
    "packageInstallKeyEnvironmentVariable": "PACKAGE_INSTALL_KEY"
}
```

Use `--init-config` / `-InitConfig` to preview or write the effective config.
Writing over an existing file requires `--force` / `-Force`; review the diff
before keeping the result. Install keys must never be stored in this JSON.

The Bash help lists its environment variables and their matching options.
PowerShell exposes the corresponding config fields and selected environment
overrides; use config for persistent project settings. Install keys may be
provided through the configured environment variable, never as an argument.

## Offline validation

These checks do not connect to Salesforce:

```bash
npm run test:scratch-org
npm run test:scratch-org:powershell
npm run test:node
npm run test:dependency-report
```

PowerShell 7 is required for the PowerShell harness. The Bash suite runs on
macOS/Linux and Bash on Windows. Tests use fake `sf`/`sfp` executables and do not
prove that authentication, org access, package installation, deployment, or
Windows enterprise policy works.
