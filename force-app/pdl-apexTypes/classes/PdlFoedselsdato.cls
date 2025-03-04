public with sharing class PdlFoedselsdato extends PdlObject {
    public Integer foedselsaar { get; }
    @TestVisible
    public Date foedselsdato { get; }
    public PDL_Folkeregistermetadata folkeregistermetadata { get; }
    public PDL_Metadata metadata { get; }
}
