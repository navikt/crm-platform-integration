# Integrasjonar

Legg teknisk dokumentasjon for eksterne system og integrasjonar her. Ta med
relevante protokollar, dataflyt og mapping, autentiseringsmønster utan
hemmelegheiter, feilhandsaming, retry og operasjonelle omsyn. Legg konkrete
driftsprosedyrar i `runbooks/` og lenk til dei her.

## Integrasjonskatalog – førsteutkast

Katalogen er eit startpunkt basert på kjeldemappene. Det er ikkje ei
stadfesting av aktive integrasjonar, miljøoppsett eller eksternt eigarskap.
Område utan eiga side er førebels berre kartlagde på oversiktsnivå.

| Område          | Dokumentasjon / kjelde                                                          | Omfang                                              |
| --------------- | ------------------------------------------------------------------------------- | --------------------------------------------------- |
| Altinn          | [Integrasjonsside](altinn/README.md)                                            | Organisasjonar og rettar, val mellom versjon 2 og 3 |
| KRR             | [Integrasjonsside](krr/README.md)                                               | Kontakt- og reservasjonsopplysningar via proxy      |
| PDL             | [Integrasjonsside](pdl/README.md)                                               | API, datatypar, Kafka-handlerar og hjelparar        |
| Felles kodeverk | [Integrasjonsside](felles-kodeverk/README.md)                                   | Henting og lagring av kodeverksdata                 |
| SMS             | [Grensesnitt](../surfaces/sms.md)                                               | Innkommande REST-kall og utgåande sending           |
| Kafka           | [Grensesnitt](../surfaces/kafka.md)                                             | Felles meldingsmottak og consumer-routing           |
| CV              | [Integrasjonsside](cv/README.md)                                                | CV-teneste og wrapperar                             |
| EREG            | [KafkaEnhetHandler](../../force-app/ereg-handler/classes/KafkaEnhetHandler.cls) | Filter og handsaming av einingsmeldingar            |
| KRP             | [Integrasjonsside](krp/README.md)                                               | Callout, personteneste og kontowrapper              |
| NOM             | [Integrasjonsside](nom/README.md)                                               | Organisasjonseiningar, ressursar og synkronisering  |
| NORG            | [Integrasjonsside](norg/README.md)                                              | Nav-einingar, kontaktinformasjon og kodeverk        |
| Representasjon  | [Integrasjonsside](repr/README.md)                                              | Fullmaktsoppslag                                    |
| TPS             | [TPS-området](../../force-app/tps/)                                             | Personteneste, callout og wrapperar                 |
| WebSak          | [Integrasjonsside](websak/README.md)                                            | Filteneste                                          |
| Skjerming       | [Handler-området](../../force-app/skjerming-handler/)                           | Kafka-handlerar og planlagde jobbar                 |

## Støtteområde

Desse områda er ikkje i seg sjølve eksterne integrasjonar:

-   [GraphQLQuery](../../force-app/GraphQLQuery/): query-byggjeklossar.
-   [Personmerge](../../force-app/mergePerson/): merge- og batchlogikk.
-   [Monitoring](../../force-app/monitoring/): planlagd integrasjonsmonitorering.
-   [Felles pakkekjerne](../../force-app/main/default/): delt kode og metadata.
-   [Scratch-org-metadata](../../force-app/scratch-org/): applikasjonar og anna
    metadata i kjeldetre; mappenamnet gir ikkje løyve til å aksessere eit org.

## Vidare utfylling

Kvar integrasjon treng stadfesta eigarskap, konsumentar, request-/response-
eller event-skjema, feltmapping, tilgangsgrunnlag, feilhandsaming, timeout,
retry/idempotens, logging og verifikasjon. Dokumenter faktisk implementasjon
og avklaringar kvar for seg. Ikkje legg inn token, persondata eller
miljøspesifikke tilgangsdetaljar.
