public with sharing class PDL_FolkeregisterIdentifikator {
    // originaly 'status' and 'type' fields are of String type
    @TestVisible
    public String identifikasjonsnummer { get; }
    @TestVisible
    public PDL_IdentStatus status { get; }
    @TestVisible
    public PDL_IdentType type { get; }
    public PDL_Folkeregistermetadata folkeregistermetadata { get; }
    @TestVisible
    public PDL_Metadata metadata { get; }
}
