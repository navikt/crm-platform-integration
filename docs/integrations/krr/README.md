# Kontakt- og reservasjonsregisteret

**Status: Førsteutkast.** Byggjer på kode og
[lokal KRR-dokumentasjon](../../../force-app/krr-integration/README.md);
nettverks- og miljøoppsettet er ikkje runtime-verifisert.

## Dataflyt

Den lokale dokumentasjonen skildrar Salesforce via SaaS-proxy til
[digdir-krr](https://github.com/navikt/digdir-krr), framfor direkte oppslag mot
Digdir. Proxyen er skildra med støtte for audit, tilgangskontroll og identoppslag.
Stadfest gjeldande eigarskap og kontrakt med ansvarleg team.

## Apex-kontrakt

[KrrCalloutService](../../../force-app/krr-integration/classes/KrrCalloutService.cls)
har `getPersons(List<String>)` og ein variant med `isSystemContext`.
Tom eller manglande identliste gir `IllegalArgumentException`.

Den undersøkte metoden brukar `ApiController` med `KRR_API` og
`POST_KRR_QUERY`, SaaS-proxy-auth-header og `Nav-Call-Id`.
`setIncludeSecureDigitalPost(Boolean)` styrer parameteren for sikker digital
post. Systemkontekst er eit eksplisitt val som må vurderast mot tilgangskrava.

Ved HTTP 200 blir responsen deserialisert til `KrrResponse`. Andre
HTTP-statusar blir logga; den undersøkte metoden kan då returnere `null`.
`CalloutException` blir logga og kasta vidare. Konsumentar må ikkje tolke
`null` som stadfesting på at ein person ikkje finst.

## Verifikasjon og opne punkt

Les [KrrCalloutServiceTest](../../../force-app/krr-integration/classes/KrrCalloutServiceTest.cls)
før endringar. Testen er ikkje køyrd her.

Avklar responsfelt som konsumentane faktisk treng, behandling av manglande
kontaktinformasjon, tilgangsgrunnlag, timeout/retry, og tillaten logging.
Eksistensen av `MaskinportenService` i same mappe betyr ikkje at alle kall frå
`KrrCalloutService` går direkte til Maskinporten.
