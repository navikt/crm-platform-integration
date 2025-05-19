# Digdir - Kontakt- og reservasjonsregisteret (KRR)

Denne pakken inneholder en service klasse for å hente ut data fra KRR.

Salesforce integrerer mot Nav's interne [digdir-krr](https://github.com/navikt/digdir-krr) som eies av Team Rocket.

Årsaken til at vi går via proxyen fremfor direkte på KRR via Maskinporten er den ekstra støtten som er bygget inn i krr proxyen. Dette inkluderer audit logging, tilgangskontroll og identstøtte via PDL. Krr proxyen har også støtte for Dolly i Dev.

## Oversikt integrasjon

### Oversikt (prod)

```mermaid
graph LR
linkStyle default interpolate linear
Saleforce-->SaaS-Proxy
SaaS-Proxy-->digdir-krr-proxy
digdir-krr-proxy-->maskinporten
digdir-krr-proxy-->krr
subgraph NAV
    Saleforce
    SaaS-Proxy
    digdir-krr-proxy
end
subgraph Digdir
    maskinporten[Maskinporten]
    krr[Kontakt- og reservasjonsregisteret]
end
```

### Oversikt (dev)

```mermaid
graph LR
linkStyle default interpolate linear
Salesforce-->Saas-Proxy
Saas-Proxy-->digdir-krr-proxy
dolly--->|Syntetiske data|digdir-krr-stub
digdir-krr-proxy-->digdir-krr-stub
digdir-krr-stub-->digdir-krr-stub-db
subgraph NAV
    Salesforce
    Saas-Proxy
    dolly[Dolly]
    digdir-krr-proxy
    digdir-krr-stub
    digdir-krr-stub-db[(database)]
end
```
