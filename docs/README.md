# Dokumentasjon

Her ligg dokumentasjon som supplerer rot-README-en, runbooks og
utviklarinstruksjonane. Bruk startpunkta under for å finne fram, og
dokumentasjonskartet for å plassere nye dokument.

## Start her

- [Kom i gang med utvikling](kom-i-gang.md): verktøy, VS Code, scratch-org,
  pakkeavhengigheiter og metadataflyt.
- [Scratch-org oppsett](scratch-org.md) og [kommandoreferanse](scratch-org-commands.md):
  tryggleiksgrenser, alle støtta flagg, config og plattformdøme.
- [Systemoversikt](architecture/systemoversikt.md)
- [Repositorystruktur](architecture/repositorystruktur.md)
- [Datamodell og konfigurasjon](architecture/datamodell.md)
- [Omgrep](domain/omgrep.md)
- [Integrasjonskatalog](integrations/README.md)
- [Kafka-kontrakt](surfaces/kafka.md) og [SMS-grensesnitt](surfaces/sms.md)

Dei tekniske sidene er førsteutkast baserte på statisk lesing av kode og
metadata. Opne punkt er markerte på sidene. Dokumentasjonen er ikkje
runtime-verifisert, og ho gir ikkje løyve til å køyre operasjonar mot eit org.

## Dokumentasjonskart

- **Arkitekturvedtak:** [`adr/`](adr/) inneheld ADR-ar og
  [ADR-mal](adr/template.md).
- **Arkitektur:** [`architecture/`](architecture/) inneheld systemoversikt,
  komponentar og gjennomgåande tekniske mønster.
- **Domene:** [`domain/`](domain/) inneheld domenetermar, forretningsreglar og
  sentrale arbeidsflytar.
- **Brukarflater og API-ar:** [`surfaces/`](surfaces/) dokumenterer kontraktar
  som konsumentar møter.
- **Integrasjonar:** [`integrations/`](integrations/) inneheld tekniske
  detaljar for eksterne integrasjonar.
- **Arbeidsflyt:** [Arbeidsflyt og dokumentasjon](arbeidsflyt-og-dokumentasjon.md)
  forklarer korleis Issue, spesifikasjon, kode, testar og dokumentasjon heng
  saman.
- **Utviklingsstandardar:** [Utviklingsstandardar](utviklingsstandarder.md)
  peikar til Nav-, Platforce- og Salesforce-standardar og repoet sine
  praktiske instruksjonar.
- **Operativ dokumentasjon:** [Runbooks](../runbooks/README.md) inneheld
  framgangsmåtar for drift, og [runbook-malen](../runbooks/template.md)
  støttar nye manuelle eller Team Platforce-operasjonar.

## Kva er kjelda til sanning?

- Salesforce-kode, metadata og testar viser faktisk implementert åtferd.
- ADR-ar under `adr/` er kjelda for vedtekne arkitekturavgjerder. Ein ADR med
  status **Foreslått** er ikkje normativ.
- Repo-eigd teknisk dokumentasjon forklarer kontraktar og design, og skal
  oppdaterast saman med endringar som påverkar henne.
- GitHub Issues er systemet for arbeidsoppgåver og opne avklaringar.
- `AGENTS.md`, `CONTEXT.md` og `.github/instructions/` gir agent- og
  utviklarkontekst; dei erstattar ikkje implementasjon eller vedtekne ADR-ar.

Skil tydeleg mellom det som er verifisert, vedteke, foreslått og uavklart. Ikkje
kopier detaljar fleire stader når ei lenkje kan brukast.
