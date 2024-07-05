public with sharing class PdlFolkeregisterpersonstatus extends PdlObject {
    @TestVisible
    public String status { get; private set; }
    @TestVisible
    public String forenkletStatus { get; private set; }
    public PDL_Folkeregistermetadata folkeregistermetadata { get; }

    public PdlFolkeregisterpersonstatus() {
    }
}
