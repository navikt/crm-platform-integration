# WebSak – filoverføring

**Status: Førsteutkast basert på filtenesta.** Mottak, vidare arkivering og
miljøkonfigurasjon er ikkje verifiserte.

## Apex-kontrakt

[WebSakFileService](../../../force-app/websak/classes/WebSakFileService.cls)
tilbyr `postFile(String fileName, Blob fileContent)` og ein variant med
`String ftpsCatalogue`.

Begge URL-kodar filnamnet med `UrlEncodingUtility`, brukar
`WEBSAK_API` / `POST_FILE_TO_WEBSAK`, set systemkontekst og sender filinnhaldet
gjennom `ApiController.addBlob`. Service-auth er `Websak`, og klassen set
`Content-Type` til `application/json`. Variasjonen med katalog sender
`ftpsCatalogue` som URL-parameter.

Dette skildrar Apex-oppsettet. Endeleg wire-format og transport må vurderast
saman med `ApiController` og gjeldande API-konfigurasjon; ikkje utlei filformat
frå content type åleine.

## Resultat og feil

Metoden returnerer `WebSakFileResponse` med `success` og `errorMessage`.
HTTP 200 blir tolka som suksess og logga med filnamn. Andre HTTP-statusar gir
`success = false` og ein feilreferanse. Det er ikkje ein eigen catch-blokk som
omset alle callout-exceptions til denne responsmodellen.

Ei vellukka overføring er ikkje dokumentasjon på at fila er journalført eller
ferdighandsama i eit nedstraums system. Ingen slik kvitteringskontroll er
synleg i den undersøkte klassen.

## Verifikasjon og avklaringar

[WebSakFileServiceTest](../../../force-app/websak/classes/WebSakFileServiceTest.cls)
er kjelde for vidare testarbeid, men er ikkje køyrd her.

Stadfest tillatne filnamn, filtypar og storleik, katalogval, tilgang, timeout,
duplikathandtering og endeleg kvittering. Filnamn og feilresponsar blir brukte
i logging og må vurderast for personvern. Manuell ny sending krev avklaring
av risiko for duplikatar og ein relevant runbook.
