# Overlevering til agenten i crm-platform-integration

**Dato:** 2026-10-23  
**Avsendar:** Konsumenten `crm-arbeidsforhold`  
**Status:** Bestilling av ei avgrensa, additiv API-endring. Ikkje implementert eller
org-verifisert her. Dokumentet kan kopierast åleine til integrasjonspakka.

## Oppdrag

Gjer det mogleg for konsumenten å injisere ei implementering av
`IAltinnCalloutService` i `AltinnCalloutService`.

Vi skal ikkje byggje ein Altinn-mock i integrasjonspakka. Vi skal gjere den
eksisterande fasaden utskiftbar slik at konsumenten kan levere eigne
organisasjons- og rettsresultat.

Les først instruksjonane og den faktiske kjelda i repositoryet ditt. Kontrakten
nedanfor er observert i lokal referansekjelde hos konsumenten og må stadfestast
mot autoritativ kjelde før endring.

## Kvifor vi treng dette

crm-arbeidsforhold skal teste si eiga løysing gjennom Experience Cloud:

- organisasjonsval og filtrering;
- søknadsrett og brukerstøtterett;
- Permit, Deny, tomme resultat og feil;
- ulike rettar per organisasjon;
- konsekvensar for UI og deling av avtalar.

Vi er ikkje interesserte i å teste Altinn sine HTTP-kall, auth, token eller
Named/External Credential i desse scenarioa. Konsumenten skal kunne køyre dei
utan Altinn-oppsett og utan Altinn-callouts.

## Observert eksisterande kontrakt

Interfacet har desse operasjonane:

```apex
public interface IAltinnCalloutService {
    Object getOrganizations(String personIdent);
    Object getRights(String personIdent, String organizationNumber, String serviceCode);
}
```

Fasaden har ein privat provider, ein konstruktør utan parameter og desse typa
operasjonane:

```text
AltinnCalloutService()
AltinnOrganizationsResponse getOrganizations(String personIdent)
AltinnRightsResponse getRights(
    String personIdent, String organizationNumber, String serviceCode
)
```

Responsklassane er offentlege indre klassar i `AltinnCalloutService`.
Fasaden castar returverdiane frå interfacet til desse klassane.
Standardkonstruktøren vel implementasjon via eksisterande feature-toggle-logikk.
`@TestVisible` på den private referansen gir ikkje konsumenten eit offentleg
runtime-utvidingspunkt.

## Føreslått additivt API

Legg til denne offentlege konstruktøren, med parameterdokumentasjon og eksplisitt
null-validering etter repositoryet sitt etablerte exception-mønster:

```text
AltinnCalloutService(IAltinnCalloutService provider)
```

Føreslått konsumentbruk, etter at endringa er levert:

```apex
IAltinnCalloutService provider = new ConsumerOwnedScenarioProvider();
AltinnCalloutService service = new AltinnCalloutService(provider);

AltinnCalloutService.AltinnOrganizationsResponse organizations =
    service.getOrganizations(personIdent);

AltinnCalloutService.AltinnRightsResponse rights =
    service.getRights(personIdent, organizationNumber, resourceName);
```

`ConsumerOwnedScenarioProvider` er berre eit illustrerande namn. Klassen skal
ikkje opprettast i integrasjonspakka eller refererast av henne.

Den nye konstruktøren må ikkje først kalle standardkonstruktøren, slå opp
feature-toggle, opprette `Altinn3CalloutService` eller validere live-oppsett.
Desse stega ville blokkere scenario-bruk utan credentials/config.

```text
Konsumenten si factory
    |
    +-- Normal modus -> new AltinnCalloutService()
    |                         |
    |                  eksisterande standardval
    |
    +-- Scenario-modus -> new AltinnCalloutService(consumerProvider)
                                      |
                           organisasjonar og rettar
                           frå konsumenten sin provider
```

## Akseptansekriterium

| ID      | Krav                                                                                                                         | Nødvendig evidens                                                                                            |
| ------- | ---------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| REQ-001 | Konsumenten kan injisere eksisterande interface. Injisert bane opprettar ikkje live-tenesta og gjer ingen eigne callouts.    | Opprett fasaden og kall begge operasjonane utan Altinn-setting/credentials; bruk ein provider utan callouts. |
| REQ-002 | Eksisterande konstruktør, metodar, interface og DTO-ar er bakoverkompatible. Fasaden vidarefører providersvar og exceptions. | Fokuserte delegeringstestar og relevante eksisterande fasadetestar.                                          |
| REQ-003 | Null blir eksplisitt avvist utan live-fallback. Pakka får ingen avhengigheit til konsumenten.                                | Null-test og kontroll av avhengigheitsretninga.                                                              |

Delegeringstestane skal kontrollere:

1. `personIdent` blir vidareført uendra til organisasjonsoppslaget.
2. Person, organisasjon og ressurs blir vidareførte uendra til rettsoppslaget.
3. Eit konkret organisasjonssvar og eit konkret rettssvar kjem uendra tilbake.
4. Eit strukturert feilresultat, til dømes `success=false` med feilmelding, ikkje
   blir omgjort til suksess.
5. Ei kontrollert provider-exception blir vidareført utan ny provider eller fallback.
6. Null-provider gir avtalt eksplisitt exception ved konstruksjon.
7. Standardkonstruktøren bevarer dagens implementasjonsval og krav.

Ein enkel test-provider kan registrere mottekne argument og returnere ferdige
DTO-ar. Det er ikkje nødvendig å simulere HTTP. Dersom testmiljøet har standard
settings frå felles setup, må testen eksplisitt sikre at injeksjonsbana òg fungerer
utan desse. Elles beviser han ikkje det viktigaste kravet.

## Kode som truleg blir berørt

- `AltinnCalloutService.cls`: additiv konstruktør og ApexDoc.
- `AltinnCalloutServiceTest.cls`, eller tilsvarande testplassering etter lokale
  reglar: ny fokusera testdekning.
- Direkte relevant API-/utviklardokumentasjon i integrasjonsrepositoryet.

Det er ikkje planlagt endring av `IAltinnCalloutService`. Bevar returtypen
`Object` og dagens DTO-ar no; ikkje gjer dette til ei større type-/API-migrering.
Stadfest at konstruktør, interface og responsklassar er tilgjengelege frå
konsumentpakken med den faktiske pakke-/namespace-modellen. Ikkje endre breitt
frå `public` til `global` utan dokumentert behov og godkjenning.

## Dette skal ikkje byggjast i integrasjonspakka

- Mock-av/på-setting, scenariotildeling eller scenariofiler.
- Aa-register-spesifikke ressursar, organisasjonar eller rettsmatriser.
- Runtime-mock-server, Apex REST-endepunkt eller HTTP-mock-transport.
- Nye auth-, credential- eller tokenløysingar.
- Admin-app, scenarioeditor eller administrasjonsteneste.
- Produksjonsbrytar for konsumenten sine scenario.
- Refaktorering av Altinn v2 eller endring av v3-responssemantikk.
- Endringar i crm-arbeidsforhold sine controllerar eller package dependency.

Altinn v2 skal utfaseast, men det er ei eiga bestilling. Denne oppgåva skal ikkje
utvide eller endre eksisterande versjonsval som del av injeksjonsendringa.

## Kva konsumenten tek ansvar for

Etter pakkeleveransen skal crm-arbeidsforhold:

1. Implementere eigen factory og scenario-provider.
2. Kople organisasjonsoppslaget i `AAREG_HomeController` og rettsoppslaget i
   `AAREG_CommunityUtils` til same factory.
3. Eige scenario, testbrukartildeling, UI-testing og cache-strategi.
4. Behandle manglande scenario-setting som modus av utan feil.
5. Krevje eksplisitt godkjend testbrukar og sperre scenario-runtime i produksjon.
6. Halde framtidig Admin-app mogleg, men utsetje app og administrasjonsteneste.
7. Kontrollere faktiske sideeffektar i testmiljø: mock Permit kan utløyse reelle
   delingar av avtalar. Provideren skal ikkje sjølv endre eller rydde produktdata.

Dette er ikkje krav om miljøvern i den generelle injeksjonskonstruktøren.
Vanleg avhengigheitsinjeksjon i produksjon er ikkje i seg sjølv ein testfunksjon.
Det er konsumenten sin scenario-provider og val av den som skal ha testvernet.

Cache-valet hos konsumenten er framleis ope. Det blokkerer ikkje dette API-et.

## Arbeidsmåte og tryggleik

- Følg repositoryet sine eigne instruksjonar og TDD-krav.
- Skriv ein fokusert test som feilar fordi injeksjons-API-et manglar; implementer
  så minste endring og køyr same test grøn.
- Køyr relevant eksisterande regresjon etterpå. Ikkje påstå at testar bestod
  dersom berre innsending til Apex-testkøyring vart fullført.
- Bruk syntetiske fixturedata og ingen secrets, faktiske personidentar eller
  hardkoda org-ID-ar.
- Denne overleveringa gir ikkje løyve til deploy, installasjon, pakkeutgiving,
  produksjonsbruk eller bruk av ein bestemt Salesforce-org. Følg lokale reglar
  og hent eksplisitt godkjenning der det krevst.
- Ved avvik mellom observert og faktisk API: rapporter avviket og eit avgrensa
  forslag før du utvidar scope.

## Kva agenten skal returnere til oss

Bruk dette som leveranseformat:

```text
Status: implementert / blokkert / krev avklaring
Autoritativt repository og branch:
Endra filer:
Faktisk offentleg konstruktør og exception-kontrakt:
Eventuelle avvik frå bestillinga:
Raud test: eksakt kommando og faktisk resultat
Grøn test: eksakt kommando og faktisk resultat
Regresjon: eksakt kommando og faktisk resultat
Blokkerte kontrollar og manglande føresetnader:
Pakke-/namespace-tilgang verifisert: korleis / ikkje verifisert
PR eller anna review-referanse dersom oppretta:
Tilgjengeleg pakkeleveranse: faktisk versjon dersom godkjend og oppretta,
elles ikkje publisert
Gjenståande handlingar før konsumenten kan bruke API-et:
```

Konsumenten oppdaterer avhengigheita først når ei faktisk kompatibel leveranse
er stadfesta og nødvendige godkjenningar er gitt. Ingen versjon skal gjettast.

## Tilleggskontekst, ikkje nødvendig for å forstå oppdraget

I crm-arbeidsforhold-repositoryet finst:

- `.github/specs/altinn-provider-injection.md`: REQ-001 til REQ-003.
- `.github/specs/altinn-consumer-scenarios.md`: konsumenten sine REQ-004 til REQ-024.
- `docs/integrations/altinn/README.md`: design og miljøpolicy.
- `docs/integrations/altinn/implementation-plan.md`: samla plan; pakkeoppgåvene er
  T003-T005 under planpunkt 2.1.

Desse filene treng ikkje finnast i mottakarrepositoryet. Denne overleveringa
inneheld heile bestillinga for integrasjonspakka.
