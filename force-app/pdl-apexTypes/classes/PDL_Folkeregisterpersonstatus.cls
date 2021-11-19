public with sharing class PDL_Folkeregisterpersonstatus {
    @TestVisible
    public String status { get; private set; }
    @TestVisible
    public String forenkletStatus { get; private set; }
    public PDL_Folkeregistermetadata folkeregistermetadata { get; }
    @TestVisible
    public PDL_Metadata metadata { get; private set; }

    public PDL_Folkeregisterpersonstatus() {
    }
}
