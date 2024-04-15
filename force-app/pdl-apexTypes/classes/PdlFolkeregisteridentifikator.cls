public with sharing class PdlFolkeregisteridentifikator extends PdlObject {
    // originaly 'status' and 'type' fields are of String type
    @TestVisible
    public String identifikasjonsnummer { get; }
    @TestVisible
    public PDL_IdentStatus status { get; }
    @TestVisible
    public PDL_IdentType type { get; }
    public PDL_Folkeregistermetadata folkeregistermetadata { get; }
}
