public with sharing class PdlUtflyttingfranorge extends PdlObject {
    @TestVisible
    public String tilflyttingsland { get; }
    @TestVisible
    public String tilflyttingsstedIUtlandet { get; }
    public String utflyttingsdato { get; }
    public PDL_Folkeregistermetadata folkeregistermetadata { get; }
}
