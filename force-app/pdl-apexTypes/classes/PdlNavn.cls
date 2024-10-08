public with sharing class PdlNavn extends PdlObject {
    @TestVisible
    public String fornavn { get; }
    @TestVisible
    public String mellomnavn { get; }
    @TestVisible
    public String etternavn { get; }
    public String forkortetNavn { get; }
    public PDL_OriginaltNavn originaltNavn { get; }
    public Date gyldigFraOgMed { get; }
    public PDL_Folkeregistermetadata folkeregistermetadata { get; }
}
