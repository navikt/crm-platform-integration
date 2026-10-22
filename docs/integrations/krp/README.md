# KRP – kontoopplysningar

**Status: Førsteutkast basert på callout-tenesta og personhjelparen.**
Miljøoppsett og aktive konsumentar er ikkje verifiserte.

## Oppslag

[KRP_CalloutService.getBankAccount](../../../force-app/krp/classes/KRP_CalloutService.cls)
brukar `ApiController`, `KRP_API` og `POST_HENT_AKTIV_KONTO`.
Tenesta set systemkontekst og SaaS-proxy-auth, sender JSON med `kontohaver`
og legg til ein korrelasjonsverdi i `nav-call-id`.

[KRP_Persons.getBankkonto](../../../force-app/krp/classes/KRP_Persons.cls)
tolkar responsen og returnerer `KRP_Konto`:

| Utfall              | Implementert åtferd                                                           |
| ------------------- | ----------------------------------------------------------------------------- |
| HTTP 200 med body   | Deserialiserer til `KRP_Konto`                                                |
| HTTP 200 utan body  | Kan returnere `null`                                                          |
| HTTP 204            | Loggar at kontohavaren ikkje har aktiv konto og kastar `KRP_PersonsException` |
| Andre HTTP-statusar | Loggar HTTP-feil og kastar `KRP_PersonsException`                             |
| Andre exceptions    | Loggar og pakkar feilen i `KRP_PersonsException`                              |

Ingen aktiv konto er altså ikkje representert som eit vanleg tomt resultat
ved HTTP 204. Konsumentar må skilje dette frå teknisk feil utan å basere seg på
ei uavklart forventning om `null`.

## Relasjon til TPS og vidare arbeid

Repoet har også [TPS_CalloutService](../../../force-app/tps/classes/TPS_CalloutService.cls),
med kontoopplysningar gjennom `TPS_PROXY` / `GET_TPS_BANKKONTO`. At begge
finst, dokumenterer ikkje at dei er likeverdige eller at migrering er fullført.
Stadfest rett inngang for kvar konsument før endringar.

Les [KRP_PersonsTest](../../../force-app/krp/classes/KRP_PersonsTest.cls) og
[callout-testen](../../../force-app/krp/classes/KRP_CalloutService_TEST.cls)
ved vidare arbeid. Dei er ikkje køyrde her.

Avklar systemeigarskap, kontrakten for manglande konto, timeout/retry og
logging av ident- og kontoopplysningar. Dokumentasjonen skal ikkje innehalde
ekte kontonummer, identar eller rå responsar med persondata.
