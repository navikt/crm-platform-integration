public with sharing class PDL_ForelderBarnRelasjon {

    public String relatertPersonsIdent{ get;}
    public PDL_ForelderBarnRelasjonRolle relatertPersonsRolle{ get;}
    public PDL_ForelderBarnRelasjonRolle minRolleForPerson{ get;}
    public PDL_Folkeregistermetadata folkeregistermetadata{ get;}
    public PDL_Metadata metadata{ get;}

    public PDL_ForelderBarnRelasjon() {

    }

    public enum PDL_ForelderBarnRelasjonRolle {
        BARN,
        MOR,
        FAR,
        MEDMOR
    }
}
