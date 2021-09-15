public with sharing class PDL_Navn {
    @TestVisible
    public String fornavn { get; private set; }
    @TestVisible
    public String mellomnavn { get; private set; }
    @TestVisible
    public String etternavn { get; private set; }
    @TestVisible
    public String forkortetNavn { get; private set; }
    @TestVisible
    public PDL_OriginaltNavn originaltNavn { get; private set; }
    @TestVisible
    public Date gyldigFraOgMed { get; private set; }
    @TestVisible
    public PDL_Folkeregistermetadata folkeregistermetadata { get; private set; }
    @TestVisible
    public PDL_Metadata metadata { get; private set; }
}
