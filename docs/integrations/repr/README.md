# Representasjon og fullmakt

**Status: Førsteutkast basert på tenesta og den lokale testen.** Ekstern
responsmodell, tilgangskrav og aktive konsumentar er ikkje stadfesta.

## Apex-inngangar

[FullmaktService](../../../force-app/repr/classes/FullmaktService.cls)
tilbyr tre statiske metodar:

| Metode                                       | Konfigurasjonsnøkkel           |
| -------------------------------------------- | ------------------------------ |
| `getFullmaktsgiver(String identNr)`          | `GET_FULLMAKTSGIVER`           |
| `getFullmaktsgiverHistorikk(String identNr)` | `GET_FULLMAKTSGIVER_HISTORIKK` |
| `getAllFullmakter(String identNr)`           | `GET_ALL_FULLMAKTSGIVER`       |

Alle brukar `ApiController` med `Representasjon_Fullmakt` og service-auth
`PDLfullmakt`. Dei sender JSON-body med feltet `ident` og legg til
`Content-Type` og ein korrelasjonsverdi i `Nav-Call-Id`.

Konfigurasjonsnamna er interne koplingsnøklar. Ikkje utlei HTTP-metode, full
URL eller eit komplett eksternt skjema frå prefikset `GET_`.

## Respons og feil

Metodane returnerer rå `HttpResponse`. Dei undersøkte metodane validerer ikkje
identparameteren, deserialiserer ikkje responsen og har ikkje eigne catch-
eller retry-blokker. Konsumenten må handtere status og body i samsvar med den
eksterne kontrakten og åtferda i det delte `ApiController`-rammeverket.

Eit oppslag på fullmakter er ikkje i seg sjølv ei tilgangsavgjerd. Bruksområdet
må avklare gyldigheit, historikk, omfang og kva handling ei fullmakt gir rett
til. Ikkje likestill desse oppslaga med Altinn-rettar.

## Testgrunnlag

[FullmaktServiceTest](../../../force-app/repr/classes/FullmaktServiceTest.cls)
set mocka HTTP 200 for kvar av dei tre konfigurasjonsnøklane og kontrollerer
statusen. Dette dokumenterer ikkje ugyldig input, tilgangsavslag,
responsmapping eller ende-til-ende-åtferd. Testen er ikkje køyrd her.

## Må avklarast

-   Systemeigar og konsumentar av kvar metode.
-   Eksternt request-/response-skjema og obligatoriske felt.
-   Tolkning av historikk, utgåtte eller tilbakekalla fullmakter.
-   Tilgangsgrunnlag, audit og dataminimering.
-   Timeout, feilstatusar og eventuelle retry-krav.

Bruk syntetiske testdata. Personidentar og responsar med personopplysningar
skal ikkje kopierast inn i dokumentasjonen.
