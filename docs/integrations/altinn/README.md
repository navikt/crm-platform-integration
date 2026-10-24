# Altinn

**Status: Førsteutkast basert på kode.** Aktive feature-flagg, credentials og
miljøoppsett er ikkje verifiserte.

## Ansvar og inngang

[AltinnCalloutService](../../../force-app/altinn/classes/AltinnCalloutService.cls)
er fasaden for `getOrganizations(personIdent)` og
`getRights(personIdent, organizationNumber, serviceCode)`.

Konstruktøren vel implementasjon gjennom feature-flagget `Altinn_Version_3`.
Flagget vel `Altinn3CalloutService` når det er aktivt, elles
`Altinn2CalloutService`. At begge klassane finst, seier ikkje kva versjon som
er aktiv i eit bestemt miljø.

Konsumentar kan også konstruere fasaden med ein eigen `IAltinnCalloutService`.
Denne banen initialiserer ikkje standardprovider eller les feature-toggle/
Altinn-innstillingar. Null-provider gir
`AltinnCalloutService.AltinnCalloutServiceException` med meldinga
`Altinn provider must not be null.` Oppslaga returnerer providersvara via dei
eksisterande castane; provider-feil blir ikkje pakka om, og null eller feil
returtype får den eksisterande cast-åtferda.

## Data og konfigurasjon

Fasaden returnerer eigne wrapperar med mellom anna `success`, `errorMessage`,
organisasjonar og rettar. Organisasjonsmodellen omfattar også underliggjande
einingar og autoriserte ressursar/roller.

[Altinn3CalloutService](../../../force-app/altinn/classes/Altinn3CalloutService.cls)
brukar `Altinn3IntegrationSetting__c` for callout-namn, endepunkt, cachepartisjon,
cache-nøkkel og subscription key. Manglande nødvendige innstillingar blir
handterte i konstruktøren. Token-cache er skild gjennom `ITokenCache` og
`PlatformTokenCache`.

Ikkje kopier verdiar for innstillingar, token eller personidentar inn i
dokumentasjonen. Namna på innstillingane er ikkje eit løyve til å lese dei frå
eit org.

## Feil og testing

Konsumentar må forhalde seg til både responsfelta og exceptions frå den valde
implementasjonen. Dette utkastet gir ikkje ein fullstendig feil- eller
retry-kontrakt for Altinn 2 og 3.

Kjeldegrunnlag for vidare arbeid:

- [AltinnCalloutServiceTest](../../../force-app/altinn/classes/AltinnCalloutServiceTest.cls)
- [Altinn3CalloutServiceTest](../../../force-app/altinn/classes/Altinn3CalloutServiceTest.cls)
- [PlatformTokenCacheTest](../../../force-app/altinn/classes/PlatformTokenCacheTest.cls)

### Samla Altinn-testsuite

[Altinn_All_Tests](../../../force-app/altinn/testSuites/Altinn_All_Tests.testSuite-meta.xml)
samlar dei tre Altinn-testklassane ovanfor,
[AltinnResponseUtilsTest](../../../force-app/altinn/classes/AltinnResponseUtilsTest.cls) og
[MaskinportenServiceTest](../../../force-app/krr-integration/classes/MaskinportenServiceTest.cls),
som testar Altinn 2 si lokale Maskinporten-/JWT-støtte. Testhjelpeklassar er
ikkje eigne suite-medlemmer. Suiten samlar eksisterande testar; medlemslista
åleine legg ikkje til ny åtferdsdekning.

Etter at suite-metadata og relevante klassar er deploya til eit godkjent
ikkje-produksjonsorg, kan suiten køyrast slik:

```bash
sf apex run test \
    --suite-names Altinn_All_Tests \
    --target-org <godkjent-ikkje-produksjonsorg> \
    --code-coverage \
    --result-format human \
    --wait 30
```

Deploy og testkøyring krev kvar si separate godkjenning av eksakt mål og handling.
Siste lokalt lagra suite-resultat frå 2026-10-24 kl. 19:43 viser 91 av 92
testmetodar bestått for dei tre Altinn-klassane. Rapporten oppgir 93 beståtte
og éin feila når setup er medrekna. Minimum-access-testen feila på testens
eige SOQL-oppslag mot `Altinn3IntegrationSetting__c`, før provider-konstruksjon.
Kontrollen av manglande settings er flytta før `System.runAs`; konstruksjon
og begge oppslaga køyrer framleis med minimumstilgang og kontrollerer null
SOQL, DML og callouts. Ingen rettar er utvida.

Ein etterfølgjande godkjend dry-run gav 93/93 beståtte testmetodar, inkludert
`MaskinportenServiceTest`. Testrettinga passerte, men deploy-valideringa feila
på klassedekning for `AltinnResponseUtils` (17/29 linjer, 58,62 %).
`AltinnResponseUtilsTest` er lagt til for avgjerder, statuskode,
autentiseringsnivå, manglande data og ugyldig JSON. Neste separat godkjende
dry-run fullførte med 98/98 beståtte testar, ingen dekningsvarsel og
`AltinnResponseUtils` dekt på 29/29 linjer. Suite-metadata vart òg validert.
Testane vart valde via `RunSpecifiedTests`, ikkje via suite-oppslag.

| Testklasse                  | Beståtte testar |
| --------------------------- | --------------: |
| `AltinnCalloutServiceTest`  |              11 |
| `Altinn3CalloutServiceTest` |              40 |
| `AltinnResponseUtilsTest`   |               5 |
| `PlatformTokenCacheTest`    |              41 |
| `MaskinportenServiceTest`   |               1 |

Den siste valideringa brukte denne kommandoforma med eksplisitt godkjent
scratch-org. `checkOnly=true`; ingen metadata vart lagra:

```bash
sf project deploy start --dry-run \
    --source-dir force-app/altinn \
    --source-dir force-app/krr-integration/classes/MaskinportenService.cls \
    --source-dir force-app/krr-integration/classes/JWT.cls \
    --source-dir force-app/krr-integration/classes/MaskinportenServiceTest.cls \
    --target-org <godkjent-scratch-org> \
    --test-level RunSpecifiedTests \
    --tests AltinnResponseUtilsTest \
    --tests AltinnCalloutServiceTest \
    --tests Altinn3CalloutServiceTest \
    --tests PlatformTokenCacheTest \
    --tests MaskinportenServiceTest \
    --json
```

### Provider-injeksjon: verifisert 2026-10-24

Dry-run av den endra fasaden og testklassa fullførte med 92 beståtte testar,
ingen feil og ingen dekningsvarsel:

- `AltinnCalloutServiceTest`: 11 testar.
- `Altinn3CalloutServiceTest`: 40 testar.
- `PlatformTokenCacheTest`: 41 testar.
- `AltinnCalloutService`: 21 av 21 køyrbare linjer dekte.

Denne køyringa brukte API 63.0 for fasaden og 56.0 for testklassa.

### API-versjon 67.0: dry-run-validert 2026-10-24

Alle 17 Apex-klassar i Altinn-området, inkludert interface, testhjelparar og
testklassar, har no API 67.0 i klassemetadata. Den lokale Altinn 2-støtta
`MaskinportenService`, `JWT` og `MaskinportenServiceTest` i KRR-området er òg
oppdatert til 67.0. Ingen dependency-pakkar eller aktiv KRR-proxy er endra.

Andre Altinn-metadatatypar, inkludert testsuite, objekt, felt og custom metadata,
har ikkje eige `apiVersion`-felt. Dei får ikkje lagt til eit slikt felt.

Versjonsløftet kan endre plattformåtferd sjølv utan endringar i Apex-kjelda.
Alle 20 klassane vart kompilerte i den godkjende dry-run-en med 98 beståtte
testar skildra ovanfor. Dette er ikkje permanent deploy eller
konsumentkompilering mot faktisk pakkeleveranse.

### Kommando og evidens frå tidlegare provider-validering

Kommandoforma under vart køyrd med eit uttrykkeleg godkjent scratch-org som mål.
Ho er dokumentasjon av valideringa, ikkje løyve til ei ny org-køyring:

```bash
sf project deploy start --dry-run \
    --source-dir force-app/altinn/classes/AltinnCalloutService.cls \
    --source-dir force-app/altinn/classes/AltinnCalloutServiceTest.cls \
    --target-org <godkjent-scratch-org> \
    --test-level RunSpecifiedTests \
    --tests AltinnCalloutServiceTest \
    --tests Altinn3CalloutServiceTest \
    --tests PlatformTokenCacheTest \
    --json
```

Testane kontrollerer innstillingsfri injeksjon, uendra argument og responsobjekt,
feil, null, feil returtype og isolasjon mellom instansar. Dei tre eksisterande
HTTP-mock-testane køyrer deterministisk med Altinn 2. Ein eigen test verifiserer
at standardkonstruktøren framleis gir Altinn 3 sin konfigurasjonsfeil når flagget
er aktivt utan settings.

Teststøtta vart stadfesta ved lesing av dei installerte dependency-klassane:
`FeatureToggleBase` les metadata gjennom `CustomMetadataDAO`, som har den
statiske `@TestVisible`-cachen `customMetadataRecordsMap`. Testane fyller denne
med minnebasert `Feature_Flag__mdt` for den eksakte SELECT-strengen frå
dependency-koden. Ingen metadata blir endra i org-en. Ved dependency-oppgradering
må denne testkoplinga kontrollerast på nytt. `BaseTestFactory.insertEncryptionKey()`
vart òg stadfesta og er behalden i eksisterande setup.

Første org-køyring etter at auth fungerte gav 6 beståtte provider-testar og
3 feila eldre testar fordi dei føresette Altinn 2 utan å styre flagget. Etter
testrettinga vart resultatet grønt som oppgitt over. Den tidlegare
kompilatorloggen for manglande konstruktør er raudt kontraktbevis, ikkje ein
fullført raud einingstest. Loggen inneheldt også testsyntaksfeil som vart retta.

Review mot spec og lokale standardar: konstruktøroverlast framfor setter bevarer
instanslokal binding og unngår live-initialisering; `with sharing` og direkte
cast er uendra. Ingen ny tilgang, runtime-mock, scenario-konfigurasjon,
produksjonsvern eller konsumentavhengigheit er innført. Tradeoffen er framleis
runtime-cast ved feil providertype. Pakke-API-et krev menneskeleg review.

**Ikkje verifisert:** kompilering frå `crm-arbeidsforhold` mot ei faktisk levert
pakke. Ingen pakkeversjon er oppretta, installert eller publisert som del av
denne valideringa, og dry-run lagra ikkje metadata. Pakkeåtkomst og overlevering
står att i [#478](https://github.com/navikt/crm-platform-integration/issues/478)
etter separat godkjenning av nødvendig leveranse. `public` er ikkje endra til
`global`.

## Må avklarast

- Eigar og konsumentar for dei ulike oppslaga.
- Mapping mellom servicekode og Altinn 3-ressursar.
- Forventa åtferd ved manglande rettar, utgått token og utilgjengeleg API.
- Gjeldande plan for Altinn 2/3 og runbook ved versjonsbyte.
- Krav til audit, logging og dataminimering.
