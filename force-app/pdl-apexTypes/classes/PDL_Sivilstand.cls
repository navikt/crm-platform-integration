public with sharing class PDL_Sivilstand {
    @TestVisible
    public PDL_Sivilstandstype type { get; }
    @TestVisible
    public Date gyldigFraOgMed { get; }
    @TestVisible
    public String relatertVedSivilstand { get; }
    public Date bekreftelsesdato { get; }
    public PDL_Folkeregistermetadata folkeregistermetadata { get; }
    public PDL_Metadata metadata { get; }
}
