public with sharing class PDL_UtflyttingFraNorge {
    @TestVisible
    public String tilflyttingsland { get; private set; }
    @TestVisible
    public String tilflyttingsstedIUtlandet { get; private set; }
    @TestVisible
    public String utflyttingsdato { get; private set; }
    @TestVisible
    public PDL_Folkeregistermetadata folkeregistermetadata { get; private set; }
    @TestVisible
    public PDL_Metadata metadata { get; private set; }
}
