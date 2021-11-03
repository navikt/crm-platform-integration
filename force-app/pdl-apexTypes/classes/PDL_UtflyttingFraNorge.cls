public with sharing class PDL_UtflyttingFraNorge {
    @TestVisible
    public String tilflyttingsland { get; }
    @TestVisible
    public String tilflyttingsstedIUtlandet { get; }
    public String utflyttingsdato { get; }
    public PDL_Folkeregistermetadata folkeregistermetadata { get; }
    public PDL_Metadata metadata { get; }
}
