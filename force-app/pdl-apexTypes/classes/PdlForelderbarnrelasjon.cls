public with sharing class PdlForelderbarnrelasjon extends PdlObject {
    @TestVisible
    public String relatertPersonsIdent { get; private set; }
    @TestVisible
    public PDL_ForelderBarnRelasjonRolle relatertPersonsRolle { get; private set; }
    @TestVisible
    public PDL_ForelderBarnRelasjonRolle minRolleForPerson { get; private set; }
    public PDL_Folkeregistermetadata folkeregistermetadata { get; }

    public PdlForelderbarnrelasjon() {
    }
}
