# ADR – crm-platform-integration

Denne mappen samler Architecture Decision Records (ADR-er) for
`crm-platform-integration` Unlocked Package. ADR-er dokumenterer viktige
arkitektur- og designbeslutninger med kontekst, vurderte alternativer, valgt
løsning og konsekvenser.

Målet er ikke å dokumentere alle implementasjonsvalg, men beslutninger som er
viktige nok til at framtidige utviklere bør forstå hvorfor pakken er utformet
slik den er.

## Når skal vi skrive en ADR?

Skriv en ADR når en beslutning:

-   påvirker flere deler av pakken eller kontrakten mot andre pakker
-   er vanskelig eller kostbar å endre senere
-   avklarer en teknisk retning for pakken
-   velger mellom flere reelle alternativer
-   påvirker sikkerhet, drift, testbarhet eller videreutvikling
-   etablerer en standard andre utviklere bør følge

Ikke bruk ADR-er til å dokumentere vanlig implementasjonsdetalj eller
beslutninger som eies av en separat pakke. Dokumenter eventuelle konsekvenser
for avhengigheter og pakkekontrakter når de er relevante.

## Format

Bruk [ADR-malen](template.md). Kvar ADR skal minimum innehalde:

-   Status
-   Dato
-   Kontekst
-   Beslutning
-   Alternativer vurdert
-   Konsekvenser
-   Oppfølging

## Navngiving og status

Navngi ADR-er med en felles løpende nummerserie og en kort tittel:
`NNNN-kort-beskrivende-tittel.md`. Nummeret angir dokumentrekkefølge, ikke et
eget faglig spor. Nye ADR-er får neste ledige nummer.

Bruk en av disse statusene:

-   **Foreslått** – beslutningen er under vurdering.
-   **Vedtatt** – beslutningen er godkjent og normativ.
-   **Erstattet** – beslutningen er erstattet av en nyere ADR; lenk til denne.
-   **Trukket** – forslaget skal ikke følges.

## ADR-er i dette repoet

Det er foreløpig ingen ADR-er i denne mappen. Neste ledige nummer er
`ADR-0001`.
