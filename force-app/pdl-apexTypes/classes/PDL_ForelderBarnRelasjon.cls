public with sharing class PDL_ForelderBarnRelasjon {
    @TestVisible
    public String relatertPersonsIdent { get; private set; }
    @TestVisible
    public PDL_ForelderBarnRelasjonRolle relatertPersonsRolle { get; private set; }
    @TestVisible
    public PDL_ForelderBarnRelasjonRolle minRolleForPerson { get; private set; }
    public PDL_Folkeregistermetadata folkeregistermetadata { get; }
    public PDL_Metadata metadata { get; }

    public PDL_ForelderBarnRelasjon() {
    }
}
