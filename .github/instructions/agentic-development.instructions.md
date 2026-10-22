---
applyTo: '**'
---

# Agentisk utvikling i crm-platform-integration

## Nav-prinsipp

Følg Nav sine Copilot-prinsipp frå [navikt/copilot](https://github.com/navikt/copilot):

-   Bruk små, fokuserte endringar og eksisterande mønster.
-   Start med deterministisk, lokal validering før breiare undersøking.
-   Bevar utviklarens forståing: forklar arkitekturval, tradeoffs og raud-sone-logikk.
-   Be om avklaring ved uklare krav og stopp før handlingar som krev menneskeleg godkjenning.
-   Ver tydeleg på kva som er verifisert, kva som er blokkert, og kva som berre er ei antaking.

## TDD-gate

Ved ny funksjonalitet eller feilretting skal agenten bruke red-green-refactor i vertikale skiver:

1. Avklar krav, observabel åtferd og testseam før kode.
2. Skriv ein test som uttrykkjer åtferda og køyr han slik at han feilar, når testmiljøet støttar dette.
3. Skriv minste implementasjon som gjer testen grøn.
4. Køyr same fokuserte test etter kvar endring.
5. Refaktorer først når åtferdstesten er grøn, og køyr testen på nytt.
6. Køyr relevant breiare validering før arbeidet blir kalla ferdig.

For Apex må agenten skilje mellom lokal Jest-validering og org-avhengig Apex-validering. Dersom ein Apex-test ikkje kan kompilerast eller køyrast utan ein autentisert org, skal agenten dokumentere dette og aldri hevde at testen er grøn.

## Før og etter kode

Før endring:

-   Finn næraste implementasjon, test og gjeldande instruks.
-   Identifiser om fila ligg i hovudpakkja eller ei pakke-eigd referansemappe.
-   Klassifiser arbeidet som grøn sone eller raud sone. Kjernelogikk, tilgang, personvern, autentisering og arkitektur krev ekstra menneskeleg gjennomgang.

Etter endring:

-   Vis kva test eller validering som blei køyrd.
-   Forklar arkitekturval og viktige tradeoffs kort.
-   Marker kode som utviklaren må forstå særleg grundig.
-   Køyr security-review før commit, push eller pull request når endringa rører secrets, auth, tilgang, persondata, callouts, metadata-tilgang eller GitHub Actions.

## Menneskeleg kontroll

Før kvar kommando som aksesserer eit Salesforce-org eller -miljø, må agenten be brukaren stadfeste nøyaktig mål-org/miljø og konkret handling. Dette gjeld scratch-org, sandbox, Dev Hub, Apex-testar, deploy preview, metadata-retrieval, deploy og skript som koplar til eit org. Ikkje utlei løyve frå autentisert alias, standardoppsett, tidlegare godkjenning eller skript. Godkjenning for éi handling gir ikkje løyve for neste handling. Dersom mål eller handling ikkje er stadfesta for denne operasjonen, stopp og spør.

Produksjon er alltid forbode. Agenten skal aldri kople til, spørje, hente metadata frå, teste mot eller deploye til produksjon, heller ikkje etter uttrykkeleg førespurnad.

Org-oppretting, pakkeinstallasjon, deploy, pakkeoppretting, pakke-promotering og endring av CI/auth krev eksplisitt godkjenning frå brukaren. Agenten skal ikkje finne på org-alias, Salesforce-ID-ar, installasjonsnøklar eller avhengigheitsversjonar.

## Nav AI-policy

-   Bruk berre GitHub Copilot Business gjennom Nav-organisasjonen til Nav-arbeid. Private Copilot-abonnement og frittståande AI-kodeverktøy er ikkje tillatne.
-   Alle modellar som er tilgjengelege gjennom Copilot Business kan brukast, men utviklaren er ansvarleg for resultatet.
-   Agent mode og lokale agentar skal køyre isolert med `cplt` eller ei tilsvarande sandbox-løysing. Agentar med uavgrensa tilgang til Nav-utstyr er ikkje tillatne.
-   Bruk berre MCP-serverar som er godkjende i Nav sin verktøykatalog.
-   Coding agent kan berre brukast til avgrensa oppgåver og må alltid ende i menneskeleg gjennomgang og godkjenning av PR før merge.
-   Utviklaren skal forstå og kritisk vurdere generert kode, skrive testar, bruke code review og køyre relevante sikkerheitskontrollar.
-   Ver ekstra varsam i raud sone: debugging, nye konsept, kjernelogikk, tilgang, persondata og sikkerheitskritisk kode.
