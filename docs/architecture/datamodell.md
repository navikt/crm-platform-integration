# Datamodell og konfigurasjon

**Status: Førsteutkast basert på metadata og utvalde klassar.** Tabellen er ei
oversikt, ikkje eit komplett ER-diagram eller ei oversikt over tilgangar.

| Objekt / metadata                 | Rolle                                                                        | Kjelde                                                                            |
| --------------------------------- | ---------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| `KafkaMessage__c`                 | Innkommande melding med topic, nøkkel, payload, status og feiltekst          | [Metadata](../../force-app/main/default/objects/KafkaMessage__c/)                 |
| `OutboundKafkaMessage__c`         | Objekt for utgåande Kafka-meldingar; transport og konsument må avklarast     | [Metadata](../../force-app/main/default/objects/OutboundKafkaMessage__c/)         |
| `KafkaMessageHandlerBinding__mdt` | Koplar topic til Apex-consumer, med sandbox-overstyring og jobbinnstillingar | [Metadata](../../force-app/main/default/objects/KafkaMessageHandlerBinding__mdt/) |
| `KafkaMessageFilterBinding__mdt`  | Koplar topic til filterklasse                                                | [Metadata](../../force-app/main/default/objects/KafkaMessageFilterBinding__mdt/)  |
| `KafkaIntegrationConfig__c`       | Styrer prosessering og sletting av ferdighandsama meldingar                  | [Metadata](../../force-app/main/default/objects/KafkaIntegrationConfig__c/)       |
| `Sync_Class_Binding__mdt`         | Klassar som `CRM_PerformSync` skal køyre                                     | [Metadata](../../force-app/main/default/objects/Sync_Class_Binding__mdt/)         |
| `SMS__c`                          | Innkommande og utgåande SMS med melding, mottakar og status                  | [Metadata](../../force-app/sms/objects/SMS__c/)                                   |
| `SMS_Config__mdt`                 | Konfigurasjon brukt ved sending og mottak av SMS                             | [Metadata](../../force-app/sms/objects/SMS_Config__mdt/)                          |
| `Altinn3IntegrationSetting__c`    | Konfigurasjon for Altinn 3-callout og token-cache                            | [Metadata](../../force-app/altinn/objects/Altinn3IntegrationSetting__c/)          |
| `Kodeverk_Codeset__mdt`           | Kodeverk som skal hentast                                                    | [Metadata](../../force-app/felles-kodeverk/objects/Kodeverk_Codeset__mdt/)        |
| `Kodeverk_Config__mdt`            | Styrer køyring av kodeverk-jobbar                                            | [Metadata](../../force-app/felles-kodeverk/objects/Kodeverk_Config__mdt/)         |
| `MaskinportenClient__mdt`         | Klientkonfigurasjon for Maskinporten-støtta                                  | [Metadata](../../force-app/krr-integration/objects/MaskinportenClient__mdt/)      |

## Viktige skilje

`AsyncRequest__c` og `Common_Code__c` blir brukte av koden, men er ikkje
definerte som objekt i dei oppførte kjeldemappene. Ikkje opprett lokale kopiar
av slike delte kontraktar. Stadfest eigarpakke og gjeldande felt ved endringar.

Apex-wrapperklassar for PDL, NOM, CV og andre API-ar er ikkje automatisk
persistente Salesforce-objekt. Dei representerer data i kode; eventuell lagring
må sporast i handler- og serviceklassane.

## Datahandtering som må avklarast

Meldingspayload, personidentifikatorar, kontaktinformasjon og SMS-innhald kan
innehalde personopplysningar. Avklar dataminimering, innsyn, tilgang,
oppbevaring og logging for kvar integrasjon. Denne kartlegginga dokumenterer
ikkje at CRUD, FLS eller deling er verifisert.

`KafkaMessageHandler` kan ved aktivert `DeleteProcessedRecords__c` både slette
ferdighandsama meldingar og tømme dei frå papirkorga. Dette er relevant for
gjenoppretting og sporbarheit; ikkje legg til grunn at payload alltid finst
etter handsaming.
