# Repositorystruktur

**Status: Førsteutkast.** Dette er ei beskriving av eksisterande struktur,
ikkje ein plan om å flytte kode.

| Område                          | Innhald                                                   |
| ------------------------------- | --------------------------------------------------------- |
| `force-app/main/default/`       | Felles Kafka-kode og Salesforce-metadata                  |
| Andre område under `force-app/` | Integrasjonar, datatypar, støttefunksjonar og testar      |
| `sfdx-project.json`             | Pakkekjelde, avhengigheiter og API-versjon                |
| `config/`                       | Konfigurasjonsfiler for Salesforce DX                     |
| `.github/workflows/`            | Automatisering for validering og pakke-/deployoperasjonar |
| `docs/`                         | Teknisk dokumentasjon og utviklingsstandardar             |
| `runbooks/`                     | Operasjonelle prosedyrar                                  |

Pakkekjelda følgjer ikkje berre `force-app/main/default/`. Til dømes ligg
Altinn i `force-app/altinn/`, medan Felles kodeverk har Apex direkte under
`force-app/felles-kodeverk/`. Følg plasseringa i området som blir endra.
Eksisterande Apex-testar ligg saman med funksjonen eller integrasjonen.

Separat eigde avhengigheiter er ikkje kjelde som skal endrast som del av ei
vanleg produktendring. Sjå [pakkegrensene](../../.copilot/reference-only.instructions.md).
At ei mappe finst lokalt, betyr ikkje at ho er med i denne pakken.

## Dokumentasjonsplassering

-   Tverrgåande mekanismar: [arkitektur](README.md).
-   Omgrep og felles språk: [domene](../domain/README.md).
-   Eksterne system og mapping: [integrasjonar](../integrations/README.md).
-   Inngangar og observerbare kontraktar: [grensesnitt](../surfaces/README.md).
-   Arkitekturavgjerder: [ADR-ar](../adr/README.md).
-   Manuelle operasjonar: [runbooks](../../runbooks/README.md).

Struktur og namngiving må vurderast mot
[utviklingsstandardane](../utviklingsstandarder.md), ikkje normaliserast gjennom
ei uavklart masseflytting.
