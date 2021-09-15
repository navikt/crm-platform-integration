public with sharing class PDL_Kjoenn {

    public PDL_KjoennType kjoenn{ get;}
    public PDL_Folkeregistermetadata folkeregistermetadata{ get;}
    public PDL_Metadata metadata{ get;}

    public PDL_Kjoenn() {

    }

    public enum PDL_KjoennType{
        MANN, KVINNE, UKJENT
    }
}
