# PDL

**Status: Førsteutkast basert på utvalde inngangar.** Full feltmapping,
Kafka-payloadar og alle PDL-handlerar er ikkje kartlagde i dette dokumentet.

## Ansvarsdeling

| Kjeldeområde                                       | Rolle                                             |
| -------------------------------------------------- | ------------------------------------------------- |
| [pdl-api](../../../force-app/pdl-api/)             | API-kall, GraphQL-queryhjelparar og responsstøtte |
| [pdl-apexTypes](../../../force-app/pdl-apexTypes/) | Apex-typar for PDL-data                           |
| [pdl-handler](../../../force-app/pdl-handler/)     | Kafka-handsaming for personrelaterte meldingar    |
| [pdl-helpers](../../../force-app/pdl-helpers/)     | Støttekode for PDL-handsaming                     |
| [GraphQLQuery](../../../force-app/GraphQLQuery/)   | Generelle GraphQL-byggjeklossar                   |

Ikkje bland eit synkront PDL-oppslag med ei Kafka-oppdatering: inngang,
tilgangskontekst og feilhandtering må vurderast for kvar flyt.

## Query-teneste

[PdlService](../../../force-app/pdl-api/classes/PdlService.cls) tilbyr
`queryData(String behandlingsnummer, String query)` og ein eldre
`queryData(String query)`-variant som er merkt deprecated.

Den eksplisitte varianten avviser tomt behandlingsnummer. Kallet brukar
`ApiController` med `PDL_API` / `POST_PDL_API`, service-auth, JSON content type,
`Tema` og `behandlingsnummer` som headerar, og returnerer `HttpResponse`.
Konsumenten må handtere HTTP-respons og innhaldet i GraphQL-responsen; metoden
åleine er ikkje ei fagleg validering av resultatet.

Den eldre varianten har eit fast behandlingsnummer. Ikkje bruk dette som
standard for nye bruksområde; avklar rett behandlingsgrunnlag og nummer.

## Vidare arbeid

-   Dokumenter felt og mapping per konsument, med dataminimering som utgangspunkt.
-   Stadfest samanhengen mellom identendringar, personmerge og Kafka-handlerar.
-   Dokumenter GraphQL-feil og delvise resultat i dei konkrete konsumentane.
-   Avklar eigarskap, auditkrav, oppbevaring og godkjende testdata.

[PdlServiceTest](../../../force-app/pdl-api/classes/PdlServiceTest.cls) og
[PDL_API_QueryTest](../../../force-app/pdl-api/classes/PDL_API_QueryTest.cls)
er kjelder for vidare verifikasjon, ikkje dokumentasjon på køyrde testar her.
