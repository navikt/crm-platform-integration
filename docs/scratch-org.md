# Scratch-org setup

This guide covers the standalone scratch-org scripts. For general developer
setup and the manual Salesforce workflow, see [developer onboarding](kom-i-gang.md).
Run all commands below from the repository root.

For all available modes, flags, configuration fields, and platform-specific
examples, see the [complete command reference](scratch-org-commands.md).

## Prerequisites and approval

The scripts use [sf-project.config.json](../sf-project.config.json)
and this repository's package dependencies.

Salesforce CLI and `sfp` are required; Bash also requires `jq`. Package keys
must be supplied through `PACKAGE_INSTALL_KEY`, never committed or passed
in command history. No permission sets, dummy users, data imports, or
community publishing are enabled by default. Dependency source retrieval
requires explicitly declared local directories; they are not created by
the setup scripts.

Agree on the target and each action with Team Platforce before accessing
Salesforce. AI agents require confirmation immediately before each
org-accessing command; production is always prohibited for agents.

PowerShell requires **PowerShell 7 LTS** (the test baseline is 7.6.6), installed
through an approved software channel. Windows PowerShell 5.1 is not supported.
CMD and npm require `pwsh.exe` on PATH and fail with installation guidance
instead of falling back to 5.1. Do not bypass execution policy, AppLocker/WDAC
or managed-machine restrictions; resolve installation through the approved channel.

Check the installed runtime with `pwsh -NoLogo -NoProfile -Command '$PSVersionTable'`.
PowerShell 7 can be installed alongside Windows PowerShell. On macOS, native
PowerShell is sufficient for the shared tests; Docker and Windows are not required.

## Run the setup scripts

```bash
npm run scratch-org -- --help
```

On macOS/Linux, use `bash bin/create-scratch-org.sh`. On Windows, use
`bin\create-scratch-org.bat` or `.\bin\create-scratch-org.ps1`; npm selects
the correct platform automatically. Windows options use PowerShell names:
`npm run scratch-org -- -DryRun` in CMD. In PowerShell, quote the separator:
`npm run scratch-org '--' -DryRun` or `npm run scratch-org '--' -Help`.
PowerShell removes an unquoted `--` before `npm.ps1` receives it; npm then
consumes options such as `-Help` instead of forwarding them. Alternatively,
use `npm.cmd run scratch-org -- -Help` or `.\bin\create-scratch-org.ps1 -Help`.

After approval for the Salesforce reads, preview the planned actions:

```bash
npm run scratch-org -- --dry-run
```

Dry-run prevents mutations but still reads pool status and package versions
from Salesforce. It requires authentication and approval for those reads;
only help and the offline regression tests can run without org access.

The default flow fetches a scratch org from the existing `dev` pool, installs
the dependencies declared in [sfdx-project.json](../sfdx-project.json), and deploys
local metadata. It does not fall back to creating a new scratch org if pool
acquisition fails. The Dev Hub comes from Salesforce CLI configuration or an
explicit `--pool-devhub <approved-dev-hub-alias>` (`-PoolDevHub` on Windows).
No Dev Hub alias or credentials are stored in the shared config.

After agreeing on the target and each action with Team Platforce, a human
can run `npm run scratch-org` (without dry-run) to execute the combined flow.
AI agents still require confirmation immediately before each org-accessing
command. The legacy install scripts are unchanged.

To exercise PowerShell itself on macOS rather than the npm launcher (which
selects Bash there), use `pwsh -NoLogo -NoProfile -File ./bin/create-scratch-org.ps1`.
This is a real, org-accessing setup command and requires the target/action approval
described above. Set the installation key through the configured environment
variable; PowerShell does not automatically read macOS Keychain.

Output includes grouped settings, numbered phases, package/post-step counters
and a final success/failure summary. Interactive terminals show a spinner with
elapsed time; redirected logs get a plain heartbeat every five seconds. Use
`-Verbose` for successful CLI details and `-Color` / `-NoColor` for explicit
styling. Failed command details are always shown and the configured key is redacted.
Dry-run summaries distinguish planned actions from completed work.

## Dependency preflight and reports

Before setup mutations, a recursive dependency preflight validates the declared
package versions, transitive requirements, and installation order. Version
numbers are compared numerically as minimum requirements: a selected version
above a transitive minimum satisfies it, and the selected version's own
dependency graph is checked. A selected version below a requirement blocks the
check; that required branch is not expanded. Missing dependency metadata fails
closed. Reports are written as Markdown/Mermaid and interactive HTML beside the
project manifest. A zero missing-package count does not certify completeness
while below-minimum requirements remain unresolved.

For a human-approved read-only check, use `--check-dependencies` in Bash or
`-CheckDependencies` in PowerShell. `--apply-dependencies` / `-ApplyDependencies`
explicitly updates the manifest with fixable missing dependencies and ordering,
with a backup; it does not create an org or install packages. Conflicts are not
automatically reconciled. Use `--dependency-report <file.md>` /
`-DependencyReport <file.md>` to override the report path. These commands read
Salesforce metadata and require the same per-operation approval as setup.

## Offline regression tests

Offline regression tests do not contact Salesforce. Run on macOS/Linux
(or in Bash on Windows):

```bash
npm run test:scratch-org
```

The portable PowerShell harness runs separately on macOS and Windows:

```powershell
npm run test:scratch-org:powershell
```

Additional local checks for the dependency report and Node contracts:

```bash
npm ci
npm run test:node
npm run test:dependency-report
```

The offline harness invokes the actual script against restrictive fake `sf`/`sfp`
executables in a path containing spaces and Unicode. It tests this repository's
configuration and declared dependencies, pool fetch, deploy, no-create fallback,
failure propagation, argument boundaries and key redaction. It cannot access real
Salesforce CLI/auth. Mac runs explicitly skip Windows-only CMD/npm scenarios.

The existing integration-specific tests are retained: alias, pool-only mode,
deploy-only defaults, declared dependencies and absence of application data steps.
Shared tests additionally cover pool fallback and precedence, invalid configuration,
CLI failures, quoting, key redaction, dependency preflight and source cleanup.
Windows-only tests verify `sfp.ps1`, CMD special characters and quoted npm separators.
They cannot be verified by a macOS run.

### CI coverage and limitations

The separately approved [offline workflow](../.github/workflows/scratch-org-offline.yml)
uses Windows 2025 with checksum-pinned PowerShell 7.6.6, read-only repository
permissions, no Salesforce secrets and no package installation. Its mandatory
Windows command is:

```powershell
pwsh -NoLogo -NoProfile -File bin/tests/create-scratch-org.Tests.ps1 -RequireWindows
```

Missing tooling or skipped mandatory Windows scenarios fail the job. A separate
Ubuntu job preserves Bash/Node regression coverage and runs the interactive
report's Jest/jsdom tests after `npm ci`. A macOS job tests the system Bash 3.2,
including cleanup with an empty `preserveRootFiles` list. Runtime, OS and revision are
recorded in job logs. Green offline results prove only the tested runner/CLI
contract, not actual Salesforce integration, managed Windows PCs, proxy/VPN,
execution policy or Windows terminal rendering. Track remaining evidence in
[navikt/crm-platform-integration#467](https://github.com/navikt/crm-platform-integration/issues/467).

<details>
<summary>Historical verification evidence (2026-10-23)</summary>

- macOS 26.7.1 ARM64 / PowerShell 7.6.6: `npm run test:scratch-org:powershell`
  passed 202 assertions; the Windows-only group was explicitly skipped.
- [Windows/Linux offline run](https://github.com/navikt/crm-platform-integration/actions/runs/40028772371),
  revision `2807225d604762ab3b9b97025001e4c2177be035`:
  Windows Server 2025 / PowerShell 7.6.6 passed 222 assertions with zero skipped
  mandatory groups using the `-RequireWindows` command above.
- The same run passed 18 Node tests on Windows (the Bash-only project test was
  skipped there), and 19 Node tests plus 224 Bash assertions on Ubuntu.
  The optional external sf-project loader check is not part of this standalone
  repository and is explicitly skipped by the Bash harness.
- Earlier Windows runs exposed native argument loss, CMD test-launch quoting
  and CRLF assertion errors. These were fixed before the green run; no Windows
  requirement was removed. This is Windows offline verification, not a successful
  authenticated Salesforce setup.

</details>
