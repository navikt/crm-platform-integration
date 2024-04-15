public with sharing class PdlSivilstand extends PdlObject {
    @TestVisible
    public PDL_Sivilstandstype type { get; }
    @TestVisible
    public Date gyldigFraOgMed { get; }
    @TestVisible
    public String relatertVedSivilstand { get; }
    public Date bekreftelsesdato { get; }
    public PDL_Folkeregistermetadata folkeregistermetadata { get; }
}
