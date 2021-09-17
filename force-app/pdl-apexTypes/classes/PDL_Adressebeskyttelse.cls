public with sharing class PDL_Adressebeskyttelse {

    public PDL_AdressebeskyttelseGradering gradering{ get;}
    public PDL_Folkeregistermetadata folkeregistermetadata{ get;}
    public PDL_Metadata metadata{ get;}

    public PDL_Adressebeskyttelse() {

    }

    public enum PDL_AdressebeskyttelseGradering{
        STRENGT_FORTROLIG_UTLAND,
        STRENGT_FORTROLIG,
        FORTROLIG,
        UGRADERT
    }
}
