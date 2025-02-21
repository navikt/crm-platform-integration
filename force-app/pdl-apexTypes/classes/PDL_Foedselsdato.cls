public with sharing class PDL_Foedselsdato {
    public Integer foedselsaar { get; }
    @TestVisible
    public Date foedselsdato { get; }
    public PDL_Folkeregistermetadata folkeregistermetadata { get; }
    public PDL_Metadata metadata { get; }

    public PDL_Foedselsdato() {
    }
}
