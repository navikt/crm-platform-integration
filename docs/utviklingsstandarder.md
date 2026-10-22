# Utviklingsstandardar for crm-platform-integration

Dette dokumentet samlar inngangane til standardane som gjeld når vi utviklar
`crm-platform-integration` Salesforce Unlocked Package. Det er ei oversikt,
ikkje ei erstatning for dei autoritative Nav-, Platforce- og Salesforce-kjeldene
eller dei detaljerte instruksjonane i dette repoet.

## Kjelder og prioritet

Utviklarar skal følgje alle relevante standardar. Bruk denne rekkjefølgja når
krav faktisk står i konflikt:

1. Gjeldande, konkrete føringar frå Team Platforce for Salesforce-utvikling.
2. Gjeldande krav og mønster i
   [Platforce Documentation](https://navikt.github.io/platforce-doc/), særleg
   [Naming Conventions](https://navikt.github.io/platforce-doc/reference/naming-conventions/).
3. Andre gjeldande Nav-standardar for Salesforce-utvikling og relevante
   generelle Nav-retningslinjer.
4. Salesforce sine gjeldande best practices, offisiell
   [Salesforce-dokumentasjon](https://developer.salesforce.com/docs/) og
   [Architecture Center](https://architect.salesforce.com/), inkludert
   [Well-Architected Framework](https://architect.salesforce.com/docs/architect/well-architected/guide/overview),
   så langt dei ikkje er overstyrte av ei relevant Nav- eller Platforce-føring.
5. Repoet sine instruksjonar og etablerte mønster, så lenge dei ikkje strir mot
   punkta over eller ei uttrykkeleg godkjend bevaring av ein eksisterande
   offentleg kontrakt.

Dette hierarkiet er ikkje ei oppmoding om å velje éi kjelde og ignorere resten:
følg alle standardar som ikkje er i konflikt. Når ei konkret føring frå Team
Platforce, Platforce Documentation eller Nav avvik frå Salesforce-råd, følg den
gjeldande Nav-/Platforce-føringa. Gjer avviket synleg i løysinga og be om
menneskeleg vurdering når konsekvensen er viktig eller uklar.

## Ansvar for å halde seg oppdatert

Kvar person som utviklar eller endrar Salesforce-løysingar i Nav, har sjølv
ansvar for å halde seg oppdatert på gjeldande Platforce-, Salesforce- og Nav-
retningslinjer, og for å bruke dei i arbeidet. Les den relevante, oppdaterte
kjelda når ei endring rører eit område du ikkje kjenner godt nok. Be om
avklaring frå Team Platforce eller rett fagmiljø når krava er uklare eller
motstridande; ikkje fyll hola med eigne antakingar.

Dokumentasjonen kan endre seg. Kontroller nettversjonane av lenkja standardar
ved planlegging og review; denne sida er ikkje ein frosen kopi av dei.

## Namngiving

Følg [Platforce Naming Conventions](https://navikt.github.io/platforce-doc/reference/naming-conventions/)
for nye Salesforce-tilpassingar og metadata:

-   Vel spesifikke, forklarande namn; unngå generiske namn som kan tyde fleire
    ting.
-   Bruk omgrep som samsvarer med gjeldande forretnings- og integrasjonsspråk.
-   Bruk engelsk for konfigurerbar metadata, API-namn, Apex og andre backend-
    identifierarar. Bruk Translation Workbench for brukarvendte omsetjingar i
    tråd med Nav- og repo-standardane.
-   Følg dei etablerte namnemønstra i den aktuelle feature- eller
    integrasjonsmappa. Ikkje finn opp nye prefiks eller endre eksisterande
    offentlege namn berre for å normalisere eldre kode.
-   Bruk dei konkrete reglane for Apex-klassar, testar, metodar og ApexDoc i
    [Apex-instruksjonen](../.github/instructions/salesforce-apex.instructions.md)
    og dei relevante lokale `AGENTS.md`-filene.

Namngivingsreglane i dette repoet må tolkast innanfor den gjeldande
Platforce-standardens rammer. Ved konflikt: ikkje masseendre eksisterande
metadata eller offentlege Apex-API-ar. Bevar kontrakten, dokumenter avviket og
behandle eventuell omnamning som ei eiga, godkjend migrering.

## Kode, metadata og arkitektur

Bruk dei detaljerte reglane som gjeld for fila du endrar:

-   [Apex](../.github/instructions/salesforce-apex.instructions.md)
-   [LWC](../.github/instructions/salesforce-lwc.instructions.md)
-   [Metadata og deklarativ utvikling](../.github/instructions/salesforce-metadata.instructions.md)
-   [Testing](../.github/instructions/salesforce-testing.instructions.md)
-   [Pakkegrenser og kjeldestruktur](../force-app/AGENTS.md)
-   [Instruksjonar for `main/default`](../force-app/main/default/AGENTS.md)

Nokre gjennomgåande krav:

-   Bevar Salesforce source format, API-namn og offentlege kontraktar.
-   Bruk `with sharing` som standard, og gjer tryggleiks- og delingsval eksplisitte.
-   Bulkifiser SOQL og DML; ikkje køyr dei inne i løkker.
-   Hald triggarar tynne og flytt forretningslogikk til eigna handler- eller
    serviceklassar.
-   Valider data ved tillitsgrenser og handter feil tydeleg. Bruk eksisterande
    logging, konfigurasjon, testdatafabrikkar og pakkekomponentar før nye
    abstraksjonar eller hardkoda verdiar.
-   Ikkje legg inn Salesforce-ID-ar, org-URL-ar, credentials, pakk nøklar eller
    personopplysningar i kode, testar, dokumentasjon eller loggar.
-   Behandle tilgang, persondata, autentisering, callouts, metadata-synlegheit
    og pakkekontraktar som risikoområde som krev særleg grundig review.

## Salesforce Well-Architected

Vurder relevante Well-Architected-dimensjonar ved designendringar:

-   **Trusted:** trygg tilgang, etterleving, vern av data og påliteleg feil- og
    gjenopprettingsåtferd.
-   **Easy:** tydeleg scope, forståeleg arbeidsflyt, vedlikehaldbar kode og
    passande automatisering.
-   **Adaptable:** robustheit, separasjon av ansvar, interoperabilitet og
    pakketerbarheit.

Bruk Salesforce Well-Architected Framework saman med Nav- og Platforce-
føringar, ikkje i staden for dei. Forklar viktige avvegingar, avhengigheiter og
konsekvensar for offentlege kontraktar.

## Test og verifisering

-   Ved ny åtferd eller feilretting: bruk red-green-refactor når eit
    gjennomførbart testseam finst. Skriv ein fokusert test, observer raud,
    implementer minste endring, observer grøn og køyr relevant breiare
    validering.
-   Apex-testar ligg saman med den aktuelle feature- eller integrasjonskoden i
    dette repoet. Følg eksisterande plassering og bruk `System.Assert.*` og
    `System.Test.*`.
-   Test offentleg og observerbar åtferd, relevante feiltilfelle og
    tryggleiksgrenser. Bruk mocks for callouts; ikkje gjer ekte nettverkskall i
    testar.
-   Køyr lokale testar, statiske kontrollar og formatering der det passar.
    Org-avhengige testar må ikkje rapporterast som beståtte utan at kommandoen
    faktisk blei køyrd og fullført.

Sjå [TDD-skillet](../.github/skills/tdd-salesforce/SKILL.md) for arbeidsflyten
og [arbeidsflyt og dokumentasjon](arbeidsflyt-og-dokumentasjon.md) for korleis
krav, kode, testar og dokumentasjon heng saman.

## Org- og miljøtryggleik

-   Før **kvar** kommando som aksesserer eit Salesforce-org eller miljø, må
    brukaren stadfeste det eksakte målet og handlinga. Dette omfattar scratch-org,
    sandbox, Dev Hub, Apex-test, deploy preview, metadata-retrieval, deploy og
    skript som koplar seg til eit org.
-   Ikkje utlei løyve frå autentisering, standardalias, tidlegare godkjenning
    eller eit skript. Stadfesting for éi operasjon gjeld ikkje automatisk for ei
    anna.
-   **Produksjon er alltid forbode.** Ikkje kople til, spørje, hente metadata frå,
    teste mot eller deploye til produksjon, heller ikkje etter førespurnad.

Følg [root AGENTS.md](../AGENTS.md) for dei fullstendige godkjennings- og
valideringsreglane.

## Dokumentasjon og arkitekturavgjerder

Oppdater repo-eigd teknisk dokumentasjon i same endring når kontraktar,
integrasjonsåtferd eller arkitektur blir endra. Bruk
[`docs/README.md`](README.md) for dokumentasjonskartet. Registrer varige eller
tverrgåande arkitekturavgjerder som ADR under `docs/adr/`, med
[ADR-malen](adr/template.md). Ikkje presenter forslag eller uverifisert
åtferd som vedteken standard.
