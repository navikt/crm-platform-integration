public with sharing class PDL_Sivilstand {
    public enum Sivilstandstype {
        UOPPGITT,
        UGIFT,
        GIFT,
        ENKE_ELLER_ENKEMANN,
        SKILT,
        SEPARERT,
        REGISTRERT_PARTNER,
        SEPARERT_PARTNER,
        SKILT_PARTNER,
        GJENLEVENDE_PARTNER
    }

    @TestVisible
    public Sivilstandstype type { get; private set; }
    @TestVisible
    public Date gyldigFraOgMed { get; private set; }
    @TestVisible
    public String relatertVedSivilstand { get; private set; }
    @TestVisible
    public Date bekreftelsesdato { get; private set; }

    @TestVisible
    public PDL_Folkeregistermetadata folkeregistermetadata { get; private set; }
    @TestVisible
    public PDL_Metadata metadata { get; private set; }
}
