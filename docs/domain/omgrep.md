# Omgrep

**Status: Førsteutkast.** Omgrepa skildrar integrasjonspakken, ikkje eit
bestemt fagprodukt eller alle eksterne system sine domenemodellar.

| Omgrep            | Tyding i denne pakken                                                                   |
| ----------------- | --------------------------------------------------------------------------------------- |
| Kafka-melding     | Ei melding representert av `KafkaMessage__c` i Salesforce                               |
| Topic             | Routingverdi i `CRM_Topic__c`, brukt til å velje filter og consumer                     |
| Nøkkel            | Meldingsnøkkel i `CRM_Key__c`; tydinga er avhengig av topic                             |
| Payload           | Innhald i `CRM_Value__c`; skjemaet er avhengig av consumer                              |
| Consumer          | Apex-klasse som implementerer `IKafkaMessageConsumer`                                   |
| Filter            | Klasse som vel kva mottatte meldingar som skal sendast vidare til async-handsaming      |
| Binding           | Konfigurasjon som koplar ein verdi eller jobbtype til ein Apex-klasse                   |
| Async request     | Arbeidsoppdrag representert av `AsyncRequest__c` i det delte async-rammeverket          |
| Reprosessering    | Ny handsaming av ei melding, mellom anna ved overgang tilbake til `Pending`             |
| Kodeverk          | Namngitt samling av kodar og tydingar som kan hentast og lagrast                        |
| Personident       | Identifikator brukt ved personoppslag; ikkje eit Salesforce-record-ID                   |
| Behandlingsnummer | Verdi som blir sendt i PDL-kall; rett verdi må avklarast for bruken                     |
| Fullmakt          | Representasjonsinformasjon handtert av området `repr`; ikkje det same som Altinn-rettar |

Ein Kafka-status seier noko om handsaminga i denne løysinga, ikkje nødvendigvis
at alle nedstraums system er oppdaterte. Ei vellukka HTTP-overføring er heller
ikkje i seg sjølv dokumentasjon på at alle faglege krav er oppfylte.

Sjå [Kafka-kontrakten](../surfaces/kafka.md) og
[integrasjonskatalogen](../integrations/README.md) for kjelder og avgrensingar.
