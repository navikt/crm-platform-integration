# Kom i gang med utvikling

Denne rettleiinga er for utviklarar som skal arbeide med
`crm-platform-integration` på Windows, Linux eller macOS. Kommandoane for
Salesforce er eksempel, ikkje dokumentasjon på ei gjennomført oppsetting.
Org-flyten er ikkje testa ende til ende som del av dokumentasjonsarbeidet.

## 1. Installer utviklarverktøya

Bruk Nav sine godkjende installasjonskanalar der det er krav om det.

| Verktøy                   | Installasjon og bruk                                                                                                                                                                                                    |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Git                       | [Last ned Git](https://git-scm.com/downloads). På Windows gir Git for Windows også shellen Husky brukar.                                                                                                                |
| Visual Studio Code        | [Last ned VS Code](https://code.visualstudio.com/download) og følg installasjonen for operativsystemet ditt.                                                                                                            |
| Salesforce Extension Pack | Opne Extensions i VS Code, søk etter **Salesforce Extension Pack** frå Salesforce, og installer [utvidingspakken](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode).                  |
| Salesforce CLI            | Følg [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_install_cli.htm). CLI-en må vere tilgjengeleg også i VS Code-terminalen.                      |
| Node.js og npm            | Bruk ein støtta [Node.js LTS](https://nodejs.org/en/download) som møter krava i lockfila. Sjå [README](../README.md#getting-started).                                                                                   |
| Java                      | Apex Language Server treng ein kompatibel JDK. Følg Salesforce si oppdaterte [Java-rettleiing](https://developer.salesforce.com/docs/platform/sfvscode-extensions/guide/java-setup.html) og Nav sine godkjende JDK-val. |

Sjå også Salesforce si
[installasjonsrettleiing for VS Code](https://developer.salesforce.com/docs/platform/sfvscode-extensions/guide/install.html).
Restart VS Code etter installasjon dersom nye verktøy ikkje blir funne i PATH.

Desse kontrollane kontaktar ikkje eit Salesforce-org:

```text
git --version
node --version
npm --version
sf --version
java -version
```

## 2. Klon og opne prosjektet

```text
git clone https://github.com/navikt/crm-platform-integration.git
cd crm-platform-integration
```

Vel **File → Open Folder** i VS Code og opne repositoryroten, der
`sfdx-project.json` ligg. Alternativt kan du bruke `code .` dersom VS Code sin
CLI er installert i PATH.

Køyr dette i den integrerte terminalen frå repositoryroten:

```text
npm ci
npm run prettier:check
git switch -c feature/your-change
```

Branch-namnet er eit eksempel. `npm ci` installerer lokale utviklaravhengigheiter
og Husky, ikkje Salesforce-pakkeavhengigheiter. Sjå
[lokal validering](../README.md#lokal-validering) for kjende testavgrensingar.

## 3. Avklar utviklingsmiljø

Avklar med Team Platforce kva ikkje-produksjonsmiljø og Dev Hub du skal bruke,
korleis tilgang blir gitt, og kva pakkeversjonar og installasjonssteg som er
godkjende. Ikkje legg innloggingsdetaljar eller installasjonsnøklar i repoet.

I eksempla under er alle verdiar i `<...>` plasshaldarar som må bytast ut.
Ikkje lim inn kommandoane uendra. Bruk eksplisitt mål på kvar kommando framfor
å stole på eit standardorg.

Ein Dev Hub kan vere knytt til produksjon. Dersom det er tilfellet, skal
AI-agenten ikkje logge inn eller opprette scratch-org gjennom denne huben;
avtal menneskeleg utføring med Team Platforce. Agentar må ha eksplisitt
stadfesting av eksakt mål og handling før kvar ikkje-produksjonsoperasjon.
Produksjon er alltid forbode for agentar.

### Logg inn i eit godkjent ikkje-produksjonsmiljø

```text
sf org login web --instance-url <approved-login-url> --alias <approved-org-alias>
```

Fullfør nettlesarinnlogginga med godkjend tilgang. I VS Code kan
**SFDX: Authorize an Org** i Command Palette brukast som alternativ; kontroller
det konkrete målet også når du brukar GUI.

## 4. Opprett eller få tildelt scratch-org

For repoet sine plattformtilpassa oppsettscript, sjå
[scratch-org-rettleiinga](scratch-org.md). Ho dekkjer føresetnader, pool-henting,
avhengigheitskontroll og offline testar. Dry-run kontaktar også Salesforce og
krev godkjenning av mål og handlingar.

### Via Team Platforce eller eksisterande workflow

Repoet har ein manuelt starta
[Create Scratch Org-workflow](../.github/workflows/helper_create-scratch-org1.yml)
som delegerer til `navikt/crm-workflows-base`. Avtal bruk før du startar han.
Gå til **Actions → [HELPER] Create Scratch Org → Run workflow** og vel branch
etter avtale.

Den [eksisterande workflow-rettleiinga](../.github/workflows/documentation/helper_create-scratch-org.md)
skildrar automatisk henting og commit av metadata og etterfølgjande sletting
av scratch-org. Den faktiske implementasjonen ligg i det eksterne workflow-repoet
og må kontrollerast før bruk; tidsgrenser og login-flyt er ikkje verifiserte her.
Login-artifact og loggar kan innehalde sensitiv tilgangsinformasjon og skal
ikkje delast eller kopierast inn i repoet.

### Manuell CLI-flyt etter godkjenning

Når godkjend Dev Hub er autentisert og scratch-org-oppretting er avklart:

```text
sf org create scratch --target-dev-hub <approved-dev-hub-alias> --definition-file config/project-scratch-def.json --alias <approved-scratch-alias> --duration-days 7 --wait 30
```

Repoet har [config/project-scratch-def.json](../config/project-scratch-def.json).
Pakkemanifestet peikar førebels på `config/scratch-def.json`, som ikkje finst
i dette kjeldetreet. Eksemplet brukar den eksisterande fila; avviket må
avklarast før ein brukar flytar som les definisjonsstien frå manifestet.

Ein ny scratch-org har ikkje automatisk pakkeavhengigheitene, metadataen eller
integrasjonstilgangane som løysinga treng.

## 5. Installer Salesforce-avhengigheiter

Bruk [sfdx-project.json](../sfdx-project.json) som oversikt over pakkekrav.
Avtal eksakte installerbare versjonar og rekkjefølgje med Team Platforce,
inkludert transitive avhengigheiter. Ein pakke-ID i `packageAliases` er ikkje
nødvendigvis ein installerbar pakkeversjon.

Køyr eitt godkjent installasjonssteg om gongen:

```text
sf package install --package <approved-package-version-id> --target-org <approved-scratch-alias> --wait 30
```

Nøkkelbeskytta pakkar krev sikker handtering av installasjonsnøkkelen etter
Team Platforce si rettleiing. Ikkje skriv nøklar i shell-historikk eller
dokumentasjon. Kontroller utfallet før neste pakke blir installert.

Ikkje køyr `bin/install-dependencies.sh` ukritisk: scriptet har faste
versjons-ID-ar og manglar eksplisitt målorg. `bin/install-scratch.sh` har også
samansette org-operasjonar og er ikkje ein verifisert, plattformuavhengig
onboarding-flyt. Ingen av desse er nødvendig for CLI-eksempla her.

## 6. Deploy metadata og tildel relevant tilgang

Etter at avhengigheitene er installerte, inspiser planlagd deploy:

```text
sf project deploy preview --source-dir force-app --target-org <approved-scratch-alias>
```

Ein preview kontaktar org-et, men utfører ikkje deploy. Etter separat
godkjenning av omfang og mål:

```text
sf project deploy start --source-dir force-app --target-org <approved-scratch-alias> --test-level RunLocalTests --wait 30
```

Bruk ein avgrensa `--source-dir` ved seinare, fokuserte endringar. Pakkekjelda
ligg i fleire undermapper under `force-app/`, ikkje berre `main/default/`.
Ta vare på jobb-ID og kontroller endeleg resultat; timeout er ikkje det same
som vellukka deploy. Ikkje bruk konflikt-overstyring som standardløysing.

[config/ssdx-config.json](../config/ssdx-config.json) listar
`INT_ManageKafkaMessages`, som også finst i kjelda. Dersom denne tilgangen er
godkjend og nødvendig for utviklingsbrukaren:

```text
sf org assign permset --name INT_ManageKafkaMessages --target-org <approved-scratch-alias>
sf org open --target-org <approved-scratch-alias>
```

Dette er ikkje ei komplett tilgangsliste for alle integrasjonar. Credentials,
API-konfigurasjon, feature-flagg, bindings og testdata må avklarast per
[integrasjon](integrations/README.md). Ein deploy åleine gir ikkje ei
ferdigkopla integrasjon.

## 7. Hent endringar og send til review

Gjer kodeendringar lokalt der det er mogleg. Dersom du har gjort godkjende
metadataendringar i scratch-org-et, kan du hente eit konkret omfang:

```text
sf project retrieve start --metadata <metadata-type:api-name> --target-org <approved-scratch-alias>
git status --short
git diff
```

Kontroller at metadataen hamnar i rett feature-/integrasjonsmappe før staging.
Manifestet har `src-temp` som default package directory; ikkje gå ut frå at
nyhenta metadata automatisk blir plassert under `force-app/`.

Fjern ikkje andre sine endringar. Køyr relevante testar og formatering, oppdater
dokumentasjon og eventuell runbook, og følg
[arbeidsflyten](arbeidsflyt-og-dokumentasjon.md) for Issue og pull request.
Ein lokal formatkontroll erstattar ikkje org-avhengig validering.

## Opprydding

Avtal sletting når scratch-org-et ikkje lenger trengst, og hent eventuelle
endringar først:

```text
sf org delete scratch --target-org <approved-scratch-alias>
```

Kontroller målet før du stadfestar. Ikkje slett eit delt miljø eller eit org
du ikkje eig.
