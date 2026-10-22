# Arbeidsflyt og dokumentasjon

Dette dokumentet forklarer korleis endringar i `crm-platform-integration` går
frå behov til implementasjon, validering og oppdatert teknisk dokumentasjon.

## Arbeidskjelder

-   **GitHub Issues** er systemet for arbeid, avklaringar og akseptansekriterium.
-   **`.github/specs/`** inneheld korte feature-spesifikasjonar når ei Issue ikkje
    gir nok detaljert kravgrunnlag.
-   **`docs/adr/`** dokumenterer arkitekturavgjerder som påverkar fleire
    komponentar, pakkekontraktar eller framtidige tekniske val.
-   **`docs/architecture/`, `docs/domain/`, `docs/integrations/` og
    `docs/surfaces/`** inneheld stabil, repo-eigd teknisk dokumentasjon.
-   **`runbooks/`** inneheld operasjonelle framgangsmåtar.
-   Salesforce-kode, metadata og testar er autoritative for kva som faktisk er
    implementert. Dokumentasjon skal ikkje framstille planlagd åtferd som
    verifisert.

Opprett Issue via [user story-malen](../.github/ISSUE_TEMPLATE/user-story.yml)
for arbeid som treng tydelege brukarbehov og akseptansekriterium.

## Arbeidsflyt for funksjonar og integrasjonar

1. **Skildre behovet.** Oppgi aktør eller system, observert problem og ønskt
   resultat. Definer kva som er utanfor omfanget.
2. **Avklar kontrakt og eigarskap.** Finn ut kva pakken eig, kva som høyrer til
   ei avhengig pakke, og kva ekstern request-, response- eller event-kontrakt
   som gjeld. Les næraste kode, metadata, testar og relevant dokumentasjon.
3. **Avklar risiko og avgjerder.** Vurder tilgang, persondata, autentisering,
   callouts, metadata-synlegheit og org-grenser. Skriv eller oppdater ADR når
   valet har varig eller tverrgåande konsekvens.
4. **Implementer ei vertikal skive.** Følg red-green-refactor når testseamet
   støttar det:
    1. Skriv ein fokusert test for observerbar åtferd.
    2. Køyr testen raud når det er mogleg.
    3. Implementer minste endring.
    4. Køyr same test grøn og refaktorer først etterpå.
    5. Køyr relevant breiare lokal validering.
5. **Valider org-avhengig åtferd berre med stadfesting.** Før kvar kommando
   som aksesserer eit Salesforce-org eller miljø, må brukaren stadfeste eksakt
   mål og handling. Tidlegare løyve eller standardalias er ikkje nok.
   Produksjon er alltid forbode.
6. **Oppdater dokumentasjonen.** Oppdater teknisk dokumentasjon i same endring
   når kontrakt, dataflyt, feilhandsaming eller arkitektur endrar seg.
7. **Rapporter evidens.** Oppgi eksakte kommandoar og resultat. Skil mellom
   køyrde og beståtte kontrollar, blokkerte kontrollar og antakingar.

## Integrasjonsdokumentasjon

Dokumentasjon under `docs/integrations/<integrasjon>/` bør, når det er relevant,
forklare:

-   eigarskap og systemgrense;
-   request-, response- eller event-kontrakt og mapping;
-   autentiseringsmønster og Salesforce-konfigurasjon utan secrets;
-   validering, timeout, retry, idempotens og feilhandsaming;
-   logging, korrelasjon og personvernomsyn;
-   teststrategi, miljøavhengigheiter og kjende avgrensingar.

Legg konkrete driftssteg i `runbooks/` og lenk til dei frå
integrasjonsdokumentasjonen. Ikkje utlei eksterne kontraktar frå mappenamn
eller eksempeldata åleine.

## Review og ferdigstilling

Før ferdigstilling skal endringa ha:

-   dekka akseptansekriteria eller dokumentert avvik;
-   fokusert test eller ei tydeleg forklaring på kvifor test ikkje kunne køyrast;
-   oppdaterte kontraktar, ADR-ar eller teknisk dokumentasjon når det er
    relevant;
-   rapporterte lokale og org-avhengige kontrollar kvar for seg;
-   menneskeleg review før merge.

Sjå [root AGENTS.md](../AGENTS.md) og
[agentisk utvikling](../.github/instructions/agentic-development.instructions.md)
for detaljert arbeidsflyt, tilgangsgrenser og valideringskrav.
