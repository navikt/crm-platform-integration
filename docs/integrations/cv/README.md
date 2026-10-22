# CV

**Status: Førsteutkast basert på tenesta og den lokale testen.**

## Inngang og request

[CV_Service.getCV(String fodselsnummer)](../../../force-app/cv/classes/CV_Service.cls)
brukar `ApiController` med `CV_API` / `GET_CV`. Kallet legg til
SaaS-proxy-auth og sender personident i headeren `fnr`.
URL-parameteren `erManuell` blir sett til `true` av implementasjonen.

Dette er ei beskriving av kva klassen sender, ikkje ei stadfesting av at alle
framtidige konsumentar har grunnlag for manuelle oppslag.

## Respons og datatypar

Metoden returnerer `HttpResponse` utan eigen deserialisering, inputvalidering
eller retry-blokk. Wrapperane under
[cv-wrappers](../../../force-app/cv/classes/cv-wrappers/) representerer mellom
anna erfaring, utdanning, kompetanse og jobbprofil. Kva felt ein konsument
brukar og eventuelt lagrar, må dokumenterast hos konsumenten.

## Testgrunnlag og opne spørsmål

[CV_ServiceTest](../../../force-app/cv/classes/CV_ServiceTest.cls) kontrollerer
HTTP 200 frå ein mock, ikkje full request-validering eller fagleg
responsmapping. Testen er ikkje køyrd her.

Avklar systemeigarskap, tilgangsgrunnlag, tydeleg skilje mellom manglande CV
og teknisk feil, timeout/retry og oppbevaring. Personident i headeren og
CV-innhald må takast med i vurderinga av logging og dataminimering.
