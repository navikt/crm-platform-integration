# NORG

**Status: Førsteutkast basert på kode og utvalde testar.** Dette dokumenterer
ikkje aktive API-endepunkt eller eit godkjent tilgangsoppsett.

## To nivå i Apex

[NorgService](../../../force-app/norg/classes/NorgService.cls) utfører callouts
gjennom `ApiController` med konfigurasjonen `NORG2_API` og service-auth `Norg2`.
Metodane returnerer `HttpResponse`.

[NorgNavUnits](../../../force-app/norg/classes/NorgNavUnits.cls) byggjer vidare
på tenesta med inputkontroll, deserialisering, personbaserte oppslag og
`NavUnitException` ved fleire typar feil.

| Oppslag               | Konfigurasjonsnøkkel i `NorgService` |
| --------------------- | ------------------------------------ |
| Einingar etter status | `GET_UNITS_FROM_STATUSES`            |
| Filtrerte einingar    | `GET_FILTERED_NAV_UNITS`             |
| Arbeidsfordeling      | `POST_NAV_UNIT_WORK_ALLOCATION`      |
| Eining etter geografi | `GET_NAV_UNIT_BY_LOCATION`           |
| Kontaktinformasjon    | `GET_NAV_UNIT_CONTACT_INFORMATION`   |
| Kontorinformasjon     | `GET_NAV_OFFICES_BY_UNIT`            |
| Kodeverk              | `GET_KODEVERK`                       |

Nøklane viser kopling til konfigurasjon, ikkje ei komplett ekstern API-rute.
Metodenamna `getNavUnitsFromSatuses` og `getNavUnitFromGeograpichLocation` er
eksisterande namn i koden; ikkje rett dei utan å vurdere konsumentane.

## Personbasert routing

Den undersøkte hjelparen utleier routing slik:

-   `INT_IsNavEmployee__c` blir brukt som verdi for skjerming.
-   `INT_DistrictNumber__c` blir prioritert framfor
    `INT_MunicipalityNumber__c` ved geografisk oppslag.
-   `INT_Confidential__c` blir omsett til diskresjonskodar: strengt fortruleg til
    `SPSF`, fortruleg til `SPFO` og ugradert til `ANY`.
-   Arbeidsfordeling brukar `CRM_GT__c` når feltet er med blant dei popula
    felta på personen, elles den andre geografikjelda.
-   `temagruppe` blir nullstilt i arbeidsfordelingshjelparen før kallet.

Dette skildrar implementasjonen, ikkje ei generell norm for korleis alle
Nav-løysingar skal tolke skjerming eller geografisk tilknyting.

## Resultat og feil

`getNavUnit` avviser tomt einingsnummer og returnerer første eining ved eit
vellukka listeoppslag. Tom respons eller tom liste ved HTTP 200 kan gi `null`.
Kontaktoppslag kan også gi `null` ved tom respons.

Fleire andre metodar kastar exception også ved tom HTTP 200-respons.
Konsumentar må derfor lese kontrakten for den konkrete metoden, ikkje bruke
éin felles regel for alle oppslag. HTTP-feil blir i fleire hjelparmetodar
logga med ein referanse som blir inkludert i exception.

Kombinerte einings-/kontaktoppslag gjer fleire kall. Vurder manglande
eining, feil i andre kall og ekstra callout-forbruk ved bruk.

## Testing og vidare arbeid

[NorgNavUnitsTest](../../../force-app/norg/classes/NorgNavUnitsTest.cls)
inneheld mellom anna mocka suksess, tomt einingsnummer og HTTP-feil.
[NorgKodeverkUtilsTest](../../../force-app/norg/classes/NorgKodeverkUtilsTest.cls)
dekker kodeverkshjelparen. Testane er ikkje køyrde her.

Stadfest eigarskap, aktive konsumentar, val av routingfelt og respons ved tomme
resultat. Dokumenter timeout/retry og tillaten logging, særleg ved
personbasert arbeidsfordeling.
