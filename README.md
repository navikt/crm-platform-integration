# crm-platform-integration

Salesforce Unlocked Package for Kafka message handling and shared integration
services.

Package source is under `force-app/`, grouped by feature and integration.
See [sfdx-project.json](sfdx-project.json) for package dependencies, versions,
and the Salesforce API version.

## Documentation

Start with the [documentation index](docs/README.md). The technical pages are
first drafts based on source inspection; open questions and verification
limitations are noted on each page.

| Topic                                        | Where to read                                                                                                                |
| -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Architecture and package boundaries          | [System overview](docs/architecture/systemoversikt.md) and [repository structure](docs/architecture/repositorystruktur.md)   |
| Objects and configuration                    | [Data model](docs/architecture/datamodell.md)                                                                                |
| Shared terminology                           | [Domain glossary](docs/domain/omgrep.md)                                                                                     |
| External integrations                        | [Integration catalogue](docs/integrations/README.md), including Altinn, PDL, KRR, NOM, NORG, and other services              |
| Entry points and contracts                   | [Kafka](docs/surfaces/kafka.md) and [SMS](docs/surfaces/sms.md)                                                              |
| Development practices                        | [Development standards](docs/utviklingsstandarder.md) and [workflow and documentation](docs/arbeidsflyt-og-dokumentasjon.md) |
| Architecture decisions                       | [ADR index and template](docs/adr/README.md)                                                                                 |
| Manual operations and Team Platforce actions | [Runbooks](runbooks/README.md) and [runbook template](runbooks/template.md)                                                  |
| Package context and AI-assisted development  | [CONTEXT.md](CONTEXT.md), [repository instructions](AGENTS.md), and [Copilot instructions](.github/copilot-instructions.md)  |

Keep test access, credentials, tokens, and environment-specific access details
in approved non-public documentation, not in this repository.

## Contents

-   [Documentation](#documentation)
-   [Getting started](#getting-started)
-   [Kafka messages](#kafka-messages)
-   [Felles kodeverk](#felles-kodeverk)
-   [Lokal validering](#lokal-validering)
-   [Contributing and ownership](#contributing-and-ownership)

## Getting started

For the complete walkthrough, see **[developer onboarding](docs/kom-i-gang.md)**:
installing VS Code and Salesforce extensions, opening the project, getting a
scratch org, installing dependent packages, deploying and retrieving metadata,
and preparing a pull request.

Install [Git](https://git-scm.com/), Node.js with npm, and
[Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) for
Salesforce development. Git for Windows provides the shell needed by Husky;
WSL is not required for the pre-commit hook.

Use a currently supported Node.js LTS release that satisfies the dependencies
in [package-lock.json](package-lock.json). The locked `lint-staged` 16.3.3
requires Node.js >=20.17. See [package.json](package.json) for this repository's
commands; tools and scripts from other Salesforce repositories are not
automatically available here.

From the repository root:

```bash
npm ci
npm run prettier:check
```

`npm ci` installs the locked dependencies and runs the Husky `prepare` script.
It does not provision a Salesforce environment. For environment preparation,
follow the [onboarding guide](docs/kom-i-gang.md#3-avklar-utviklingsmiljø)
and agree on the target and actions with Team Platforce before proceeding.
Do not treat existing scripts or authenticated aliases as approval.

### Standalone scratch-org scripts

The standalone scripts use [sf-project.config.json](sf-project.config.json)
and this repository's package dependencies. Run from the repository root:

```bash
npm run scratch-org -- --help
npm run scratch-org -- --dry-run
```

On macOS/Linux, use `bash bin/create-scratch-org.sh`. On Windows, use
`bin\create-scratch-org.bat` or `.\bin\create-scratch-org.ps1`; npm selects
the correct platform automatically. Windows options use PowerShell names:
`npm run scratch-org -- -DryRun`. Help works with `--help` on both platforms.

Dry-run prevents mutations but still reads pool status and package versions
from Salesforce. It requires authentication and approval for those reads;
only help and the offline regression tests can run without org access.

The default flow fetches a scratch org from the existing `dev` pool, installs
the dependencies declared in `sfdx-project.json`, and deploys local metadata.
It does not fall back to creating a new scratch org if pool acquisition fails.
The Dev Hub comes from Salesforce CLI configuration or an explicit
`--pool-devhub <approved-dev-hub-alias>` (`-PoolDevHub` on Windows).
No Dev Hub alias or credentials are stored in the shared config.

Salesforce CLI and `sfp` are required; Bash also requires `jq`. Package keys
must be supplied through `PACKAGE_INSTALL_KEY`, never committed or passed
in command history. No permission sets, dummy users, data imports, or
community publishing are enabled by default. Dependency source retrieval
requires explicitly declared local directories; they are not created by
the setup scripts.

After agreeing on the target and each action with Team Platforce, a human
can run `npm run scratch-org` (without dry-run) to execute the combined flow.
AI agents still require confirmation immediately before each org-accessing
command. The legacy install scripts are unchanged.

Offline regression tests do not contact Salesforce. Run on macOS/Linux
(or in Bash on Windows):

```bash
npm run test:scratch-org
```

The PowerShell harness can be run separately on Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\bin\tests\create-scratch-org.Tests.ps1
```

## Kafka messages

Incoming JSON payloads are stored as `KafkaMessage__c` records, using
`CRM_Topic__c`, `CRM_Key__c`, and `CRM_Value__c`. The trigger handler groups
messages by topic, applies configured filters, and creates processing requests
through the async framework from `crm-platform-base` when processing is enabled.

`KafkaMessageAsyncJob` loads the messages and delegates to `KafkaMessageService`,
which selects `IKafkaMessageConsumer` implementations through Custom Metadata.
Consumer exceptions can propagate to the async framework; they do not
necessarily become errors on individual message records.

See the [Kafka contract](docs/surfaces/kafka.md) for bindings, sandbox topic
overrides, statuses, reprocessing, and deletion behaviour. Topic-specific
payloads and idempotency requirements must be established with each consumer.

### Synchronous kafka message handling

To process incoming kafka messages in a synchronous context the following
pattern should be followed:

1. Definition of a separate platform event with the exact data model as i.e.
   defined
   [here](https://github.com/navikt/crm-platform-oppgave/tree/master/force-app/main/default/objects/Kafka_Oppgave_Event__e).
2. Create a trigger and separate trigger handler to process the incoming events.
3. The processing itself should be implemented using the `IKafkaMessageConsumer`
   interface such that error handling can be performed easily storing failed
   events as `KafkaMessage__c` records. An example of this can be viewed
   [here](https://github.com/navikt/crm-platform-oppgave/blob/master/force-app/main/default/classes/kafka/CRM_KafkaOppgaveEventHandler.cls)
   where _doEventTransform_ performs the transformation from the custom event to
   the `KafkaMessage__c` model and the failed events are stored as
   `KafkaMessage__c` records in an error status.

## Felles kodeverk

`KodeverkCalloutService` contains methods for fetching codes from Felles
kodeverk for ad hoc use or for storing them as `Common_Code__c` records. For
details, see the [integration guide](docs/integrations/felles-kodeverk/README.md)
and [Kodeverk runbook](runbooks/kodeverk/index.md).

## Lokal validering

```bash
npm ci
npm run prettier:check
node --test scripts/tests/pre-commit.test.cjs
```

Formatering og hook-testar er lokale kontrollar; dei verifiserer ikkje
Apex-kompilering, metadata eller pakkeinstallasjon.

`npm test` er definert til å starte LWC Jest, men `package.json` og lockfila
deklarerer ikkje `@salesforce/sfdx-lwc-jest` eller dei ekstra
testavhengigheitene som `jest.config.js` refererer til. Ein rein `npm ci` gir
derfor ikkje eit komplett Jest-oppsett. Dette må avklarast før LWC-testar kan
reknast som ein reproduserbar lokal kontroll. Hook-testane blir køyrde separat
med kommandoen over, ikkje som del av `npm test`.

Apex-kompilering, Apex-testar og validering mot org-tilstand er org-avhengige.
Ved agentassistert arbeid krev kvar org-operasjon stadfesting av eksakt mål
og handling; produksjon er alltid forbode for agentar. Sjå
[utviklingsstandardane](docs/utviklingsstandarder.md) for miljø- og
godkjenningsreglar.

### Pre-commit på Windows, Linux og macOS

Husky installeres av `prepare`-scriptet ved `npm install` eller `npm ci`.
Bruk Git (Git for Windows på Windows), Node.js som støttes av avhengighetene
(`lint-staged` 16.3.3 krever Node.js >=20.17), og npm. Git og Node må være
tilgjengelige i PATH også når commit startes fra VS Code.

[Hooken](.husky/pre-commit) starter [Node-scriptet](scripts/pre-commit.cjs),
som kontrollerer staged filer mot pakkemappene i `sfdx-project.json` og deretter
kjører lokalt installert `lint-staged`. Verken `jq`, `grep`, `npx` eller WSL
er nødvendig. Husky bruker fortsatt Git sin shell; LF-linjeskift for hooken
er sikret i `.gitattributes`.

Endringer i andre pakkemapper enn `force-app` blokkeres. Eksisterende unntak
med miljøvariabelen `ALLOW_PACKAGE_DIR_COMMIT=1` krever eksplisitt godkjenning
og hopper bare over pakkekontrollen, ikke formateringen. Feil i konfigurasjon,
Git eller formatering stopper commit.

Kjør isolerte hook-tester uten å endre repoets Git-indeks:

```bash
node --test scripts/tests/pre-commit.test.cjs
```

## Contributing and ownership

Describe proposed work and acceptance criteria in a
[GitHub issue](https://github.com/navikt/crm-platform-integration/issues/new/choose),
then follow the [development workflow](docs/arbeidsflyt-og-dokumentasjon.md).
Keep changes focused, update related documentation, and report exact validation
results in the [pull request template](.github/PULL_REQUEST_TEMPLATE.md).

GitHub reads [.github/CODEOWNERS](.github/CODEOWNERS) before the root
[CODEOWNERS](CODEOWNERS); the files currently have different scopes. Check the
effective ownership rules and request the relevant team's review rather than
assuming every path has automatic reviewer coverage.

Changes needing manual work or Team Platforce actions require a
[runbook](runbooks/README.md). Refer to the development standards for approvals
and production-change responsibilities.

Test
