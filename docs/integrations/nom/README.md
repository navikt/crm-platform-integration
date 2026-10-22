# NOM

**Status: Førsteutkast basert på statisk kjeldelesing.** Aktive jobbar,
miljøkonfigurasjon og eksternt eigarskap er ikkje verifiserte.

## Oppslag og synkronisering

NOM-området inneheld API-teneste, query- og mappinghjelparar, responswrapperar
og synkronisering til Salesforce. Skil mellom eit oppslag som returnerer data,
og synkronisering som endrar lagra einingar og leiarroller.

[NOM_Service](../../../force-app/nom/classes/NOM_Service.cls) byggjer på
`ApiController`. `queryData(String query)` set systemkontekst, brukar
`NOM_API` / `POST_NOM` og service-auth for `gcpsaasproxy`, og sender queryen
som body. Ein generert korrelasjonsverdi blir brukt i logging og `Nav-CallId`.
Metoden returnerer `HttpResponse`; han validerer ikkje sjølv den faglege
responsen.

[NOM_OrgEnhetHelper](../../../force-app/nom/classes/NOM_OrgEnhetHelper.cls)
har query-, parsing- og mappinglogikk. `queryData` handterer HTTP-feil og
deserialiserer til `NOM_Response`. Klassen eksponerer også `Callable`-handlingar
for leiar- og kontoreiningsoppslag. Desse er dynamiske inngangar som må takast
med ved endring av klassenamn eller metodar.

## Lokal datamapping

[NOM_Sync.updateAllUnits](../../../force-app/nom/classes/NOM_Sync.cls) hentar
einingstreet under ei rot, med djupneparameter ti, og byggjer eit flatt kart.
Deretter samanliknar han med lagra `NomUnit__c` og leiarroller i `NomRole__c`.

| NOM-verdi       | Salesforce-felt på `NomUnit__c` |
| --------------- | ------------------------------- |
| `id`            | `INT_NomId__c`                  |
| `navn`          | `Name`                          |
| `orgEnhetsType` | `INT_UnitType__c`               |
| `nomNivaa`      | `INT_NomLevel__c`               |
| `orgNiv`        | `INT_OrgLevel__c`               |
| `remedyEnhetId` | `INT_RemedyEnhetId__c`          |

Nye einingar blir sette aktive. Eksisterande einingar som ikkje finst i
resultatkartet, blir deaktiverte. Leiarrollene brukar mellom anna namn,
Nav-ident og e-post frå ressursmodellen; roller for einingar som ikkje lenger
finst i kartet, blir sletta.

Eit ufullstendig datagrunnlag kan derfor påverke både aktiv-status og roller.
Avklar fullstendigheit og avgrensing av hierarkiet før ei manuell køyring.

## Køyring og feil

[NOM_Sync_Schedule](../../../force-app/nom/classes/NOM_Sync_Schedule.cls)
startar ein `@future(callout=true)`-metode som kallar synkroniseringa.
Ingen bestemt tidsplan er stadfesta av dette dokumentet.

Synkroniseringa har separate DML-steg for einingar og roller og fangar
`DmlException` med logging. Ikkje tolk normal retur som garanti for at alle
steg lykkast; resultat og loggar må kontrollerast. Det er ikkje ein eksplisitt
rollback av alle tidlegare steg i dei undersøkte catch-blokkene.

## Testgrunnlag og avklaringar

-   [NOM_Service_Test](../../../force-app/nom/classes/NOM_Service_Test.cls)
    kontrollerer mocka HTTP-suksess, ikkje full ende-til-ende-synkronisering.
-   [NOM_Sync_Test](../../../force-app/nom/classes/NOM_Sync_Test.cls) og
    [NOM_OrgEnhetHelper_Test](../../../force-app/nom/classes/NOM_OrgEnhetHelper_Test.cls)
    er vidare kjelder. Ingen Apex-testar er køyrde for dette dokumentet.

Avklar systemeigar, konsumentar, korrekt rot/djupne, oppdateringsfrekvens,
tilgang til ressursdata og kontroll etter delvise feil. Manuell
synkronisering og opprydding krev ein [runbook](../../../runbooks/template.md).
