public with sharing class PDL_InnflyttingTilNorge {
    @TestVisible
    public String fraflyttingsland { get; private set; }
    @TestVisible
    public String fraflyttingsstedIUtlandet { get; private set; }
    @TestVisible
    public PDL_Folkeregistermetadata folkeregistermetadata { get; private set; }
    @TestVisible
    public PDL_Metadata metadata { get; private set; }
}
