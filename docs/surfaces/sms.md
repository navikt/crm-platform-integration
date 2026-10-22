# SMS: mottak og sending

**Status: Førsteutkast basert på mottakar, trigger-handler og callout-teneste.**
Dette er ikkje ei ferdig leverandørspesifikasjon eller verifisering av
endepunkttryggleik.

## Innkommande REST-kall

[SMSReceiverService](../../force-app/sms/classes/SMSReceiverService.cls)
definerer `@RestResource(urlMapping='/receiveSMS/*')` og ein `@HttpPost`-metode.
Full URL, autentisering og tilgjengelege brukarar må avklarast for miljøet.
Klassen er deklarert `global without sharing`; deklarasjonen dokumenterer ikkje
at tilgangsmodellen er godkjend.

Koden les desse JSON-stiane:

| JSON-sti                  | Bruk                                          |
| ------------------------- | --------------------------------------------- |
| `source`                  | Avsendar og grunnlag for person-/kontooppslag |
| `content.userData`        | Meldingsinnhald                               |
| `route.number`            | Mottakar                                      |
| `route.platformPartnerId` | Oppslag i SMS-konfigurasjon                   |

Mottakaren opprettar `SMS__c` med status `Received` og type `Incoming SMS`.
Personoppslaget kan gi kontotilknyting; domenet kjem frå `SMS_Config__mdt`.
Innsettingsfeil blir logga i ein catch, medan parsing og konfigurasjonsoppslag
skjer før denne catchen. Koden definerer ikkje ei fullstendig eksplisitt
HTTP-feilrespons for alle ugyldige input. Ikkje lov konsumentar ein bestemt
feilkode eller kvitteringsgaranti utan vidare test og avklaring.

## Utgåande meldingar

[SMSHandler](../../force-app/sms/classes/SMSHandler.cls) legg utgåande
`Pending`-meldingar i Queueable-jobbar, med opptil ti meldingar per gruppe.
Handleren har også vilkår for ny sending ved overgang frå `Could not send`
til `Pending`; ikkje tolk dette som ein generell automatisk retry-policy.

[SMSCalloutService](../../force-app/sms/classes/SMSCalloutService.cls)
byggjer JSON med `source`, `destination`, `userData`, `platformId` og
`platformPartnerId`, basert på melding og konfigurasjon. Han normaliserer
mottakarnummer før callout. HTTP-respons og videre statusoppdatering må
sporast gjennom Queueable-implementasjonen ved kontraktsendringar.

## Må avklarast

-   Leverandøreigarskap, autentisering og autorisasjon for mottaksendepunktet.
-   Obligatoriske felt og stabil feilrespons.
-   Kvitteringar, duplikatar, retry og leveringsgaranti.
-   Oppbevaring, tilgang og logging av telefonnummer og meldingsinnhald.
-   Ende-til-ende-test med godkjende, syntetiske data.
