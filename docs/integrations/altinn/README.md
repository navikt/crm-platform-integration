# Altinn

**Status: Førsteutkast basert på kode.** Aktive feature-flagg, credentials og
miljøoppsett er ikkje verifiserte.

## Ansvar og inngang

[AltinnCalloutService](../../../force-app/altinn/classes/AltinnCalloutService.cls)
er fasaden for `getOrganizations(personIdent)` og
`getRights(personIdent, organizationNumber, serviceCode)`.

Konstruktøren vel implementasjon gjennom feature-flagget `Altinn_Version_3`.
Flagget vel `Altinn3CalloutService` når det er aktivt, elles
`Altinn2CalloutService`. At begge klassane finst, seier ikkje kva versjon som
er aktiv i eit bestemt miljø.

## Data og konfigurasjon

Fasaden returnerer eigne wrapperar med mellom anna `success`, `errorMessage`,
organisasjonar og rettar. Organisasjonsmodellen omfattar også underliggjande
einingar og autoriserte ressursar/roller.

[Altinn3CalloutService](../../../force-app/altinn/classes/Altinn3CalloutService.cls)
brukar `Altinn3IntegrationSetting__c` for callout-namn, endepunkt, cachepartisjon,
cache-nøkkel og subscription key. Manglande nødvendige innstillingar blir
handterte i konstruktøren. Token-cache er skild gjennom `ITokenCache` og
`PlatformTokenCache`.

Ikkje kopier verdiar for innstillingar, token eller personidentar inn i
dokumentasjonen. Namna på innstillingane er ikkje eit løyve til å lese dei frå
eit org.

## Feil og testing

Konsumentar må forhalde seg til både responsfelta og exceptions frå den valde
implementasjonen. Dette utkastet gir ikkje ein fullstendig feil- eller
retry-kontrakt for Altinn 2 og 3.

Kjeldegrunnlag for vidare arbeid:

-   [AltinnCalloutServiceTest](../../../force-app/altinn/classes/AltinnCalloutServiceTest.cls)
-   [Altinn3CalloutServiceTest](../../../force-app/altinn/classes/Altinn3CalloutServiceTest.cls)
-   [PlatformTokenCacheTest](../../../force-app/altinn/classes/PlatformTokenCacheTest.cls)

## Må avklarast

-   Eigar og konsumentar for dei ulike oppslaga.
-   Mapping mellom servicekode og Altinn 3-ressursar.
-   Forventa åtferd ved manglande rettar, utgått token og utilgjengeleg API.
-   Gjeldande plan for Altinn 2/3 og runbook ved versjonsbyte.
-   Krav til audit, logging og dataminimering.
