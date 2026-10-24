# Feature Specification: Full utfasing av Altinn 2

**Oppretta:** 2026-10-24

**Status:** Utkast for review; berre spec og arbeidsoppgåver er bestilte.

**Utgangspunkt:** Arbeidskopien på `AltinnMockFeature`, inkludert provider-injeksjon.

## Scope Baseline

### Behov og vedtak

Integrasjonspakka skal ikkje lenger tilby Altinn 2. Standardfasaden skal bruke
Altinn 3 utan versjonstoggle. Konsumenteigen provider-injeksjon skal fungere som
før, utan Altinn-oppsett.

Brukaren har uttrykkeleg valt:

-   Full sletting av den offentlege `Altinn2CalloutService` etter dokumentert
    konsumentkontroll og godkjend migrering.
-   Standardverdien i `AltinnOrganizationsResponse.altinnVersion` blir `v3`.
    Dette er ei tilsikta kontraktendring. Fasaden skal ikkje omskrive resultat
    frå ein injisert provider.

Dette er ei separat endring frå [provider-injeksjonen](altinn-provider-injection.md).
Godkjenning av sluttmålet er ikkje godkjenning av deploy, pakkeutgiving,
credentials-opprydding eller produksjonstilgang.

### Kartlegging og kjeldegrunnlag

Statisk søk i `force-app`, `docs` og `runbooks`, lesing av fasaden, v2-klassa,
v3-referansar, testar, metadata og pakke-manifest. Ingen org er aksessert i
denne spesifikasjonsrunden. Eksterne konsumentar og faktisk miljøbruk er ikkje
kartlagde. Lokal mangel på referansar beviser ikkje at eit offentleg API er ubrukt.

Inventaret har åtte arbeidsflater, ikkje åtte slettingsvedtak:

| Flate | Observert ansvar | Planlagt behandling |
| --- | --- | --- |
| `AltinnCalloutService` | Toggle vel v2/v3; organisasjons-DTO startar med `v2` | Direkte v3-standardbane; DTO-standard `v3`; injeksjon bevart |
| `Altinn2CalloutService` og klassemetadata | Offentleg v2-API, inkludert to- og trearguments `getRights`; token-cache | Fjern etter konsument- og leveransegate |
| `AltinnCalloutServiceTest` | Tre v2 HTTP-mock-testar, toggle-fixture og provider-testar | Erstatt v2/toggle-testar med standard-v3-bevis; bevar provider-dekning |
| `Feature_Flag.Altinn_Version_3` og `Altinn_Version_3` custom permission | Versjonsval og påkravd custom permission | Slettingskandidatar etter krysspakke-/tilgangskontroll |
| `API_Base_Configuration.ALTINN_API`, `API_Service_Configuration.GET_ALTINN_ORGANIZATIONS`, `API_Service_Configuration.GET_ALTINN_RIGHTS` | Konfigurasjon som v2 bruker | Slettingskandidatar etter eigarskaps- og brukskontroll |
| `MaskinportenClient.salesforce_altinn_test`, `Maskinporten` remote site | Ligg i Altinn-området; klientmetadata er brukt av v2 | Vurder kvar for seg; ikkje slett ut frå plassering åleine |
| Følgjeavhengigheiter og cache | V2 er einaste funne lokale produksjonsbrukar av `MaskinportenService`, som bruker lokal `JWT`; v3 bruker òg `local.tokens` | Vurder ubrukt v2-avhengigheitskjede; bevar aktiv KRR-proxy og v3-cache |
| Dokumentasjon og miljøkonfigurasjon | Integrasjonsoversikt, kontekst, installert metadata og eventuelle credentials | Oppdater dokumentasjon; eigarstyrt runbook for miljøopprydding |

V2 refererer også klientnamnet `salesforce_altinn` og cache-nøkkelen
`altinntokendata`. Klientnamnet er ein kodereferanse, ikkje bevis på ein lokal
metadatafil eller ein autorisert credential. Konfigurasjonen refererer Named
Credential-namnet `Altinn`; faktisk eigarskap og bruk må avklarast av ansvarleg
utan å kopiere credential-verdiar til spec eller issue.

### Avgrensa følgjeopprydding etter Altinn 2

Oppdraget er Altinn 2-utfasing, ikkje generell modernisering av KRR eller auth.
Kartlegginga omfattar likevel komponentar som mistar siste produksjonsbrukar
når v2 blir fjerna, uavhengig av kva mappe dei ligg i.

Lokal kjeldekontroll viser:

-   `KrrCalloutService` bruker `ApiController` og proxy-auth gjennom
    `addSaasProxyServiceAuthHeader()`, ikkje `MaskinportenService`.
-   `MaskinportenService` blir brukt i produksjonskode av `Altinn2CalloutService`.
    Andre funne lokale referansar er eigen test og profiltilgang.
-   Den lokale `JWT`-klassa blir konstruert av `MaskinportenService`.
    Altinn 3 bruker Salesforce sin `Auth.JWT`/`Auth.JWTUtil`, ikkje denne klassa.
-   `MaskinportenClient__mdt` med felt/layout, klientpostane
    `salesforce_altinn_test` og `salesforce_krr_test`, tilhøyrande testklasse,
    profilreferansar og gamle token-Remote Sites må vurderast som den same
    avhengigheitskjeda. Ein testreferanse er ikkje i seg sjølv ein aktiv
    produksjonskonsument.
-   `local.tokens`, `PlatformTokenCache`, cache-adapterar, `AltinnRequestBuilder`,
    `AltinnResponseUtils` og `MockAltinnJWTGenerator` har v3-bruk og skal bevarast.
    V2-nøkkelen `altinntokendata` blir vurdert separat frå cachepartisjonen.

Dette er slettingskandidatar, ikkje bevis på at dei offentlege klassane eller
metadataen er ubrukt utanfor repositoryet. Konsumentkontroll, metadataeigarskap
og operativ godkjenning gjeld framleis. Ingen auth-/KRR-redesign er inkludert.

### Utanfor omfanget

-   Ingen ny Altinn 3-mapping, rettssemantikk, auth-løysing eller cache-policy.
-   Ingen runtime-scenario, scenario-config eller produksjonsvern.
-   Ingen endring av `IAltinnCalloutService` sine signaturar eller DTO-felt.
-   Ingen migrering frå `public` til `global`.
-   Ingen fjerning av delte dependency-pakkar eller endring av deira versjonar.
-   Ingen automatisk credentials-revokering, org-opprydding eller destruktiv deploy.
-   Ingen produksjonsaksess for agenten.

## User Scenarios & Testing

### User Story 1 – Eintydig Altinn 3-standardbane (P1)

Som konsument vil eg at standardfasaden alltid vel Altinn 3, slik at utfasa
Altinn 2 ikkje kan bli aktivert av flagg eller rettar.

**Uavhengig test:** Kall standardfasaden med og utan nødvendige v3-settings.

1. **Given** gyldig v3-oppsett, **When** standardfasaden gjer begge oppslaga,
   **Then** gjeld eksisterande v3-resultat og feilkontrakt.
2. **Given** manglande v3-oppsett, **When** standardfasaden blir oppretta,
   **Then** blir dagens eksplisitte v3-konfigurasjonsfeil kasta utan v2-fallback.
3. **Given** ulike verdiar/tilgangar for det gamle versjonsflagget,
   **When** konsumenten bruker standardfasaden, **Then** påverkar dei ikkje valet.

### User Story 2 – Bevare konsumenteigen provider (P1)

Som konsument vil eg at injeksjon framleis er innstillingsfri og vidarefører
provideren sine svar og feil.

**Uavhengig test:** Køyr provider-testane utan v3-settings.

1. **Given** ein injisert provider, **When** begge oppslaga blir kalla,
   **Then** blir argument, objektidentitet, resultatfelt og exceptions bevarte.
2. **Given** ein provider som returnerer eigen `altinnVersion`, null eller feil
   type, **When** fasaden delegerer, **Then** gjeld tidlegare vidareførings- og
   cast-kontrakt utan normalisering.
3. **Given** ein ny organisasjons-DTO, **When** ingen versjon er eksplisitt sett,
   **Then** er standarden `v3`; eksisterande andre standardfelt er uendra.
4. **Given** null-provider, **When** konstruktøren blir kalla, **Then** gjeld
   same exception-type og eksakte melding som før.

### User Story 3 – Trygg sletting utan følgjeskadar (P1)

Som pakke- og integrasjonseigar vil eg at v2 blir fjerna først når konsumentane
er klare, og at delte tenester og operativ gjenoppretting er ivaretekne.

**Uavhengig test:** Review konsumentinventar og slettingsmanifest; kompiler
godkjende konsumentar og køyr relevant Altinn-/KRR-regresjon.

1. **Given** ein direkte v2-konsument eller ukjend eigar, **When** sletting blir
   vurdert, **Then** blir ho blokkert til migrering eller eksplisitt avklaring.
2. **Given** metadata brukt av andre pakkar/integrasjonar, **When** v2 blir
   fjerna, **Then** blir den delte metadataen og funksjonaliteten bevarte.
3. **Given** ferdig godkjend kjeldeendring, **When** miljøopprydding blir planlagd,
   **Then** har kvart steg eigar, eksakt API-namn, godkjenning og verifikasjon.

### Edge Cases

-   Fråvær av flagg er ikkje eit signal om å velje v2.
-   Manglande v3-oppsett skal ikkje bli skjult av tomt svar eller fallback.
-   `success=false`, Deny, Indeterminate og NotApplicable skal ikkje endre meining.
-   Direkte bruk av den offentlege v2-klassa, også toarguments `getRights`,
    kan finnast utanfor repositoryet.
-   Metadata fjerna frå kjelde er ikkje nødvendigvis sletta frå installerte org-ar.
-   Rollback etter offentleg API-/metadatasletting kan ikkje føresetjast å vere
    ein enkel nedgradering av ei installert pakke.

## Requirements

### Functional Requirements

-   **REQ-001:** Kartlegg konsumentar av fasade, direkte v2-API, DTO-standardverdi
    og v2-metadata; noter eigar, migreringsstatus og ukjend bruk som blokkering.
-   **REQ-002:** Standardfasaden skal berre velje Altinn 3 og bevare eksisterande
    v3-konfigurasjonsfeil, utan versjonstoggle eller v2-fallback.
-   **REQ-003:** Provider-konstruktør, null-kontrakt, signaturar, DTO-felt, sharing,
    direkte cast og uendra vidareføring skal bevarast.
-   **REQ-004:** Nye organisasjons-DTO-ar skal starte med `altinnVersion='v3'`.
    Tilsikta åtferdsendring skal testast og formidlast til konsumenteigarane.
-   **REQ-005:** Fjern `Altinn2CalloutService` og klassemetadata etter godkjend
    konsumentmigrering. Ingen skjult kompatibilitetsstub som held v2 i live.
-   **REQ-006:** Klassifiser alle metadata-kandidatar som «slett», «behald» eller
    «uavklart» med evidens. Berre godkjende v2-eksklusive element skal fjernast.
-   **REQ-007:** Kartlegg og fjern godkjende følgjeavhengigheiter som mistar siste
    produksjonsbrukar etter Altinn 2, også utanfor Altinn-mappa. Bevar aktiv
    KRR-proxy, v3-støtte, delte cachepartisjonar og dependency-pakkar. Offentleg
    API og metadata krev konsumentkontroll før sletting.
-   **REQ-008:** Erstatt v2-/toggle-testar med åtferdstestar for v3-standardbane.
    Bevar provider-testane og relevante feil-/regresjonstestar; ingen testskipping.
-   **REQ-009:** Dokumenter endeleg kontrakt, godkjende brot, konsumentmigrering,
    slettingsinventar, operativ rekkjefølgje, verifikasjon og gjenopprettingsplan.
-   **REQ-010:** Pakkevalidering og konsumentkompilering skal bruke faktisk
    godkjend leveranse. Kjeldesletting skal ikkje rapporterast som org-sletting.
    Org-/pakkeoperasjonar krev separat godkjenning per mål og handling.

### Føresetnader, avgjerder og leveransegatar

Dette er raud sone: offentleg API-sletting, tilgang/toggle, auth-konfigurasjon og
rettsoppslag. Ansvarleg må godkjenne migreringsvedtaket og ADR før implementasjon
av den brotande delen. Eksisterande provider-endring må vere eit identifisert
grunnlag; issues [#476](https://github.com/navikt/crm-platform-integration/issues/476),
[#477](https://github.com/navikt/crm-platform-integration/issues/477) og
[#478](https://github.com/navikt/crm-platform-integration/issues/478) blir ikkje
automatisk lukka eller rekna som pakkeleverte.

Uavklart inventar, miljøberedskap og konsumentbruk er leveranseblokkerarar,
ikkje grunnlag for å gjette ein cutover-dato eller pakkeversjon. Team Platforce
må avklare kva metadata som kan slettast i faktisk pakkeleveranse, og kva som
krev manuelle steg. Agenten skal ikkje verifisere eller slette i produksjon;
det er ansvarleg menneske sitt arbeid.

Tilrådd sluttmål er direkte v3-standardbane og sletting, framfor permanent
deprecation eller ein ny factory. Tradeoff: mindre runtime-kompleksitet og ingen
uventa v2-fallback, men tap av gammal rollback-bane og offentleg v2-API.
Konsumentkontroll og operativ plan må kompensere for dette.

## Success Criteria

-   **SC-001:** Alle identifiserte konsumentar har eigar og dokumentert resultat
    for v3-overgang; ingen uavklarte konsumentar ved godkjend cutover.
-   **SC-002:** Standardoppslag bruker berre v3; ingen kjende variantar av gammalt
    flagg eller rettar kan aktivere v2.
-   **SC-003:** Alle avtalte provider-scenario og relevante Altinn-/KRR-testar
    passerer; ingen felt-/feilendring utover den godkjende DTO-standarden.
-   **SC-004:** Alle godkjende v2-eksklusive element er fjerna frå leveransen og
    dokumentert handterte per målmiljø; ingen delte element blir sletta.
-   **SC-005:** Kvar godkjend konsument kompilerer mot faktisk leveranse utan
    direkte v2-bruk. Ingen uavklarte slettings- eller gjenopprettingssteg står att.

## Validering og arbeidsdeling

Arbeidsoppgåver og avhengigheiter:

-   [#479](https://github.com/navikt/crm-platform-integration/issues/479):
    konsument-/metadatainventar og godkjend utfasing.
-   [#480](https://github.com/navikt/crm-platform-integration/issues/480):
    implementasjon med TDD; blokkert av #479.
-   [#481](https://github.com/navikt/crm-platform-integration/issues/481):
    verifisert leveranse og opprydding; blokkert av #479 og #480.

1. Konsument-/metadatainventar, ADR og menneskeleg godkjenning.
2. TDD for v3-standardbane og `v3`-DTO-standard; provider-regresjon; fjerning av
   v2 og godkjend kjeldemetadata. Kvar åtferdsendring får reelt raudt/grønt bevis.
3. Runbook og kontrollert leveranse: pakke-/konsumentkompilering, miljøverifikasjon,
   godkjend opprydding og overlevering til eigarane.

Baseline for provider-arbeidet var 92 beståtte Apex-testar i dry-run
(11 fasade, 40 v3, 41 cache). Det er ikkje testbevis for denne framtidige
utfasinga. KRR/Maskinporten-regresjon må leggjast til når delte flater blir
vurderte. Køyr smalaste test først; dokumenter eksakte kommandoar og resultat.
Ved manglande org-godkjenning skal kontrollen stå som ikkje køyrd.

Dokumentasjonen som må oppdaterast ved implementasjon omfattar Altinn-sida,
relevant system-/integrasjonsoversikt og `CONTEXT.md`. Eldre spesifikasjonar er
historisk grunnlag: lenk til dette nye vedtaket i staden for å omskrive tidlegare
verifikasjon som om ho skjedde utan v2.
