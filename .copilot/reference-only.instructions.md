---
applyTo: '**'
---

Desse mappene er berre for referanse og/eller pakke-eigde:

-   src-temp
-   platform-data-model
-   custom-metadata-dao
-   custom-permission-helper
-   feature-toggle
-   record-type-cache
-   crm-platform-base
-   crm-platform-reporting
-   crm-platform-access-control
-   crm-thread-view
-   crm-shared-timeline
-   crm-community-base
-   crm-platform-email-scheduling
-   crm-journal-utilities
-   crm-shared-user-notification
-   crm-shared-flowComponents
-   crm-platform-oppgave
-   crm-henvendelse-base
-   crm-henvendelse

Reglar for AI/agentar:

-   Ikkje opprett, endre, flytt eller slett filer i desse mappene.
-   Innhaldet kan lesast for kontekst og referanse.
-   Dersom ei oppgåve krev endring i desse mappene, stopp og be om eksplisitt godkjenning frå brukar før du held fram.
-   Ved eksplisitt godkjenning skal endringar avgrensast til minimum nødvendig omfang.

Teknisk handheving:

-   `.husky/pre-commit` blokkerer staged endringar i package-katalogane frå
    `sfdx-project.json`, unnateke `force-app` som er hovudkjelda i dette repoet.
-   Andre mapper i lista over blir ikkje blokkerte av denne hooken; dei er
    agentreglar og krev framleis eksplisitt godkjenning før endring.
-   Eit eksplisitt godkjent naudunntak for dei blokkerte package-katalogane
    krev `ALLOW_PACKAGE_DIR_COMMIT=1`.
