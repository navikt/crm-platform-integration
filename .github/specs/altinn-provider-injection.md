# Feature Specification: Avgrensa Altinn provider-injeksjon

**Oppretta:** 2026-10-23  
**Status:** Spesifikasjon for review. Ikkje implementert eller org-verifisert.  
**Repository:** `navikt/crm-platform-integration`  
**Kjeldebaseline:** branch `docs/developer-onboarding`, commit
`f175d6560938047f150ce1f2da8e52a7b2cb95a0`.

Grunnlag: [overleveringa frå konsumenten](../../docs/integrations/altinn/package-agent-handoff.md),
[AGENTS.md](../../AGENTS.md), [pakkereglane](../../force-app/AGENTS.md),
[CONTEXT.md](../../CONTEXT.md) og
[arbeidsflyten](../../docs/arbeidsflyt-og-dokumentasjon.md).
Denne runden omfattar berre kjeldekontroll, avklaringar og spec, ikkje kode eller testar.

## Scope Baseline

**Oppdaging:** Statisk lesing av Altinn-fasaden, interfacet, begge
live-implementasjonane, næraste testar, klassemetadata, feature-flagg,
pakke-manifest og integrasjonsdokumentasjon. Søk etter lokale konsumentar,
exception-mønster og teststøtte.

**Funne kontraktflater:** Fem produksjonsklassar: fasaden, interfacet, v2,
v3 og responsmappinga i `AltinnResponseUtils`. Tre direkte relevante
testklassar: fasade-, v3- og token-cache-testane.

**Avgrensa framtidig endringsflate:** `AltinnCalloutService.cls`,
`AltinnCalloutServiceTest.cls` og direkte relevant
[Altinn-dokumentasjon](../../docs/integrations/altinn/README.md).
Altinn-koden ligg i hovudpakka under `force-app/altinn/`, ikkje i ei
referansemappe. Ingen endring av interfacet, DTO-felt, live-implementasjonar,
metadata, pakkeversjonar eller avhengigheiter er bestilt.

### Stadfesta eksisterande kontrakt

| Flate                                                                             | Observert i autoritativ lokal kjelde                                                                                                                                                                  |
| --------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [IAltinnCalloutService](../../force-app/altinn/classes/IAltinnCalloutService.cls) | `public` interface med `Object getOrganizations(String personIdent)` og `Object getRights(String personIdent, String organizationNumber, String serviceCode)`.                                        |
| [AltinnCalloutService](../../force-app/altinn/classes/AltinnCalloutService.cls)   | `public with sharing`, privat `@TestVisible` provider og berre offentleg konstruktør utan parameter. Ingen offentleg injeksjon eller eigen exception-type finst.                                      |
| Fasademetodane                                                                    | Delegerer direkte og castar til dei offentlege indre klassane `AltinnOrganizationsResponse` og `AltinnRightsResponse`. Ingen catch, fallback, argumentnormalisering eller responsomskriving.          |
| Standardkonstruktøren                                                             | `FeatureToggleBase.isFeatureEnabled('Altinn_Version_3', FeatureToggle.ToggleType.FEATURE_FLAG)` vel v3 når resultatet er sant, elles v2.                                                              |
| [Altinn3CalloutService](../../force-app/altinn/classes/Altinn3CalloutService.cls) | Konstruktøren les og validerer `Altinn3IntegrationSetting__c` og opprettar token-cache. Manglande oppsett gir `Altinn3CalloutServiceException`. Dette må injeksjonsbana omgå.                         |
| Tredje rettsargument                                                              | Fasaden/interfacet kallar det `serviceCode`; v2 brukar servicekode, medan v3 brukar ressurs. Verdien skal vidareførast uendra, ikkje omsetjast eller omdøypast i denne endringa.                      |
| V3-rettsresultat                                                                  | Permit gir `success=true`; Deny gir `success=false`, `errorMessage='Access denied'` og ein rett med Deny. Indeterminate og NotApplicable har òg eksisterande feilsemantikk. Dette skal ikkje endrast. |
| DTO-standardar                                                                    | Organisasjonssvar startar med `success=false`, `altinnVersion='v2'` og null-lister; rettssvar startar med `success=false` og null-liste. Ingen ny normalisering skal leggjast til.                    |
| [Pakke-manifest](../../sfdx-project.json)                                         | `force-app` er `crm-platform-integration`; namespace er tom. Konsumenten er opplyst av brukaren å ha tom namespace òg. Faktisk kompilering på tvers av pakkene er ikkje utført.                       |

### Avvik og avklaringar

-   Overleveringa stemmer med dei observerte signaturane og delegeringa.
-   Null-exception var ikkje spesifisert konkret. Brukaren har valt ny offentleg
    indre `AltinnCalloutService.AltinnCalloutServiceException` og eksakt melding
    `Altinn provider must not be null.` Dette er eit planlagt tillegg, ikkje eit
    eksisterande API.
-   Brukaren har stadfesta at provider-retur av null eller feil type skal følgje
    dagens cast-åtferd. Null-retur er ikkje det same som null-provider.
-   Eksisterande fasadetestar bruker standardkonstruktøren og HTTP-mock, men
    beviser ikkje isolert begge toggle-utfalla eller innstillingsfri injeksjon.
    V3-testane opprettar settings i felles setup.
-   Feature-toggle-avhengigheita si kjelde og `BaseTestFactory` vart ikkje
    funne lokalt. Ingen støtta toggle-overstyring for testar er stadfesta.
    Verifiser avhengigheita sitt faktiske test-API før testutforming; ikkje finn
    opp eit API eller legg til ein ny produksjonsseam for å få testen til å gå.

### Utanfor omfanget

Integrasjonspakka skal ikkje byggje scenario-provider for runtime, scenariofiler,
rettsmatriser, scenario-konfigurasjon, factory, adminflate, HTTP-mock-teneste,
nye auth-/credential-løysingar, cache-policy eller produksjonsvern for scenario.
Dette eig `crm-arbeidsforhold`. Ein privat provider-dobbel i ein `@IsTest`-klasse
er tillaten som testfixture, ikkje som runtime-funksjonalitet.

Ingen endring av v2/v3-versjonsval, utfasing av v2, v3-responssemantikk,
konsumentkode eller `public` til `global`. Behov for dette skal rapporterast
og godkjennast som eiga scope-endring.

## User Scenarios & Testing

### User Story 1 – Bruke konsumenteigen provider utan Altinn-oppsett (P1)

Som konsumentutviklar vil eg bruke fasaden med min eigen provider slik at
organisasjons- og rettsoppslag ikkje krev live-Altinn når provideren ikkje gjer det.

**Uavhengig test:** Konstruer fasaden gjennom det nye offentlege API-et og
kall begge operasjonane med ein registrerande provider-dobbel utan callouts.

1. **Given** ingen Altinn 3-settings og ein provider utan callouts,
   **When** fasaden blir konstruert med provideren og begge oppslaga blir kalla,
   **Then** blir argumenta vidareførte uendra og akkurat providersvara returnerte,
   utan live-initialisering eller eigne callouts.
2. **Given** to fasadeinstansar med kvar sin provider,
   **When** oppslaga blir kalla om kvarandre,
   **Then** brukar kvar instans sin provider utan global tilstand.

### User Story 2 – Bevare resultat, feil og eksisterande bruk (P1)

Som konsument vil eg at injeksjon ikkje skal tolke rettar eller skjule feil,
og at eksisterande bruk av standardkonstruktøren held fram uendra.

**Uavhengig test:** Kontroller offentlege utfall for kvar operasjon og køyr
regresjon for standardbana.

1. **Given** eit konkret DTO-svar, inkludert tom liste eller `success=false`
   med feilmelding, **When** oppslaget blir kalla, **Then** kjem same objekt og
   feltverdiar tilbake utan normalisering.
2. **Given** ei kontrollert provider-exception, **When** kvar av operasjonane
   blir kalla, **Then** blir exception vidareført utan wrapping, retry eller fallback.
3. **Given** provider-retur null eller feil DTO-type, **When** fasaden castar,
   **Then** blir null vidareført, respektive plattforma sin cast-exception kasta.
4. **Given** eksisterande standardbruk, **When** feature-toggle vel v2 eller v3,
   **Then** gjeld dagens val, oppsettskrav og feilkontrakt framleis.

### User Story 3 – Avvise ugyldig provider ved konstruksjon (P1)

Som konsumentutviklar vil eg få ein eintydig feil straks ved null-provider.

**Uavhengig test:** Kall den nye konstruktøren med null utan Altinn-settings.

1. **Given** null-provider, **When** konstruktøren blir kalla, **Then** blir
   `AltinnCalloutService.AltinnCalloutServiceException` kasta med meldinga
   `Altinn provider must not be null.`, utan live-fallback.

### Edge Cases

-   Tomme, null eller uvanlege metodeargument skal ikkje få ny validering i
    fasaden; provider får den opphavlege verdien.
-   Ingen garanti om callout-fri køyring dersom den injiserte provideren sjølv
    gjer callouts. Provideren eig sine effektar og feil.
-   `altinnVersion` skal vidareførast, ikkje utleiast frå konstruktør eller toggle.

## Requirements

### Functional Requirements

REQ-ID-ane frå overleveringa blir bevarte.

-   **REQ-001 – Injeksjon:** Legg til
    `public AltinnCalloutService(IAltinnCalloutService provider)`.
    Bana skal berre validere og binde provideren til instansen. Ho skal ikkje
    kalle standardkonstruktøren, lese feature-toggle eller Altinn-konfigurasjon,
    opprette live-tenester/token-cache eller utføre SOQL, DML eller callouts.
    Begge offentlege oppslag skal bruke den injiserte provideren.
-   **REQ-002 – Bakoverkompatibilitet og delegering:** Bevar standardkonstruktør,
    interface, metodesignaturar, synlegheit, DTO-ar og direkte cast.
    Argument, svarobjekt, feilresultat og exceptions skal vidareførast uendra;
    kvar operasjon skal kalle provideren nøyaktig éin gong utan retry/fallback.
    Standardbana skal bevare dagens toggle-val og oppsettskrav.
-   **REQ-003 – Ugyldig provider og eigarskap:** Null-provider skal avvisast ved
    konstruksjon med den avtalte exception-typen og meldinga ovanfor, før
    live-initialisering. Ingen suksessforma fallback eller logging av persondata.
    Pakka skal ikkje få avhengigheit til konsumenten eller runtime-scenario.
    Dokumenter den nye konstruktøren og exception-typen med ApexDoc etter
    gjeldande reglar, og oppdater integrasjonsdokumentasjonen ved implementasjon.

### Kontraktgrenser

Fasaden held fram som `with sharing`. Injeksjon gir ikkje nye rettar eller
CRUD/FLS-unntak; provideren har ansvar for tryggleiken i si implementering.
Ingen ny Aura-, REST- eller invocable-inngang blir introdusert. Fasaden legg
ikkje til caching, persistens eller transaksjonsgrenser og omgår ikkje
Salesforce sine callout-/DML-reglar for provideren.

### Design og tradeoff

Tilrådd: éin konstruktøroverlast som brukar eksisterande interface, med ein
eigen indre exception for null. Alternativet, ein offentleg setter, tillèt
providerskifte etter konstruksjon og krev framleis at standardkonstruktøren
køyrer først. Det oppfyller ikkje behovet utan fleire endringar.

Avveging: enkel, instanslokal injeksjon framfor factory/config i denne pakka.
Det bevarer ansvarsskiljet, men `Object`-interfacet gir framleis runtime-cast
ved feil providertype. Dette er uttrykkeleg akseptert, ikkje grunnlag for
ei type-migrering. Trusted/Easy/Adaptable vurdert etter lokale reglar:
eksplisitte feil og inga ny tilgang, liten endringsflate og uendra live-bane,
og eit eksisterande variasjonspunkt utan nye runtime-abstraksjonar.
Pakke-API og rettsresultat er raud sone og krev menneskeleg review.

## Success Criteria

### Measurable Outcomes

-   **SC-001:** Begge oppslaga fungerer utan Altinn-oppsett når den leverte
    provideren ikkje treng det; fasaden legg til null eksterne kall.
-   **SC-002:** Alle avtalte delegerings-, feil- og grenseutfall er dekte av
    fokuserte testar med uendra argument og svar, og eksisterande relevant
    regresjon passerer utan endring av forretningsforventningar.
-   **SC-003:** Null-provider gir nøyaktig éin avtalt konstruksjonsfeil og ingen
    alternativ provider. Ingen runtime-scenario eller konsumentavhengigheit er lagt til.
-   **SC-004:** Konsumentkode kan implementere interfacet, konstruere fasaden,
    bruke begge responsklassane og referere den nye exception-typen mot faktisk
    kompatibel pakkeleveranse. Før dette er kompilert, er pakkeåtkomst uverifisert.

## Planlagt TDD-evidens og leveransegatar

Ingen av kontrollane nedanfor er køyrde i denne spesifikasjonsrunden.

| Skive                 | Raudt bevis før implementasjon                                                                                                                               | Grønt bevis og regresjon                                                                                                                                      |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Injeksjon, REQ-001    | Fokusert Apex-test brukar manglande konstruktør. Registrer faktisk kompilatorfeil som raudt kontraktbevis, ikkje som ein køyrd testfeil.                     | Same test kompilerer og fullfører; begge oppslag utan settings, eksakte argument, same svarreferansar, eitt providerkall per operasjon og ingen nye callouts. |
| Feil/grenser, REQ-002 | Éin fokusert test per åtferd før eventuell tilhøyrande kodeendring. Testar for allereie bevart åtferd kan vere grøne straks; ikkje fabrikker raudt resultat. | Begge operasjonar: strukturert feil, tom liste, null, feil type og provider-exception. Verifiser òg isolasjon mellom to instansar.                            |
| Null, REQ-003         | Fokusert test for den avtalte exception-kontrakten før null-validering blir implementert.                                                                    | Eksakt exception-type og melding, ingen fallback, utan Altinn-settings.                                                                                       |
| Standardbane, REQ-002 | Avklar reelt toggle-test-API før nye testar. Manglande teststøtte er ein gate, ikkje løyve til å utvide scope.                                               | Bevis begge toggle-utfalla gjennom offentleg åtferd, inkludert eksisterande v3-feil utan settings; køyr fasade-, v3- og token-cache-regresjon.                |
| Pakkeåtkomst, SC-004  | Ikkje del av lokal Apex-einingstest.                                                                                                                         | Seinare kompilering frå konsumenten mot godkjend faktisk leveranse, utan endring til `global`.                                                                |

Testfixture skal vere privat/testavgrensa og bruke syntetiske data,
`System.Assert.*`, `System.Test.*` og minimum-access `System.runAs` etter
[testreglane](../instructions/salesforce-testing.instructions.md).
Testane må eksplisitt sikre at settings manglar; felles setup med settings
er ikkje bevis på konfigurasjonsfri injeksjon. Kontroller òg kjeldebana:
null callouts åleine beviser ikkje fråvær av toggle-oppslag/live-initialisering.

Før implementasjon må ansvarleg avklare toggle-teststøtte og nødvendig
testmiljø. Dersom ein raud Apex-test ikkje kan kompilerast/køyrast med godkjend
org-operasjon, stopp ved skriven test etter TDD-reglane; ikkje påstå grønt.
Jest og formatering er ikkje bevis på Apex- eller pakkeåtkomst.

Eksakt ikkje-produksjonsorg og handling må stadfestast før kvar org-kommando.
Deploy, installasjon og pakkeutgiving krev separate godkjenningar.
Produksjonsaksess er forbode. Ingen pakkeversjon eller testkommando med
oppdikta org-alias er fastsett her.

Gjenstår før levering: godkjenning av spec og raud-sone-design, sporbar
arbeidsoppgåve og vurdering av ADR-behov etter repoarbeidsflyten, faktisk
red-green-regresjon med kommandoar/resultat, review og pakkeåtkomstbevis.
Denne specen gir ingen implementasjons-, org- eller utgivingsgodkjenning.
