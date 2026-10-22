# Felles kodeverk

**Status: Førsteutkast basert på kode og eksisterande runbook.**

## Teneste og dataflyt

[KodeverkCalloutService](../../../force-app/felles-kodeverk/KodeverkCalloutService.cls)
har tre sentrale inngangar:

-   `getCodes(String label)` hentar og mappar kodar til `Common_Code__c` utan at
    denne metoden lagrar dei.
-   `storeCodes(Set<String> labels)` legg eitt Queueable-oppdrag per label i kø.
-   `storeAllCodes()` hentar unike label-verdiar frå `Kodeverk_Codeset__mdt` og
    sender dei til `storeCodes`.

Tenesta implementerer også `Schedulable`. At ho kan planleggjast, betyr ikkje
at ein bestemt jobb er aktiv i eit miljø.

`KodeverkQueueable` hentar og mappar kodar før lagring gjennom
`KodeverkBatchable`. `EnqueueEnabled__c` på `default`-konfigurasjonen i
`Kodeverk_Config__mdt` avgjer om queueable-jobben utfører henting og lagring.
Dette er ein kontroll ved køyring, ikkje ein garanti for at jobbar ikkje blir
lagde i kø.

## Feil og drift

Queueable-klassen loggar callout-feil og uventa feil. Ein køyrd jobb må derfor
verifiserast mot forventa data og logging, ikkje berre at eit oppdrag blei
oppretta.

Den eksisterande [runbooken](../../../runbooks/kodeverk/index.md) skildrar
Named Credential, bruk og administrasjon. Bevar operasjonelle steg der,
framfor å duplisere dei her.

## Verifikasjon og avklaringar

Les [KodeverkCalloutServiceTest](../../../force-app/felles-kodeverk/KodeverkCalloutServiceTest.cls)
før endring. Testen er ikkje køyrd her.

Stadfest eigarskap, kva kodeverk konsumentane treng, oppdateringsfrekvens og
korleis forelda eller inaktive kodar skal presenterast for konsumentane.
