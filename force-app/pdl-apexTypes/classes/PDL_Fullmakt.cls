public with sharing class PDL_Fullmakt {

    @TestVisible
    public String motpartsPersonident{ get;}
    @TestVisible
    public PDL_FullmaktsRolle motpartsRolle{ get;}
    @TestVisible
    public String[] omraader{ get;}
    @TestVisible
    public Date gyldigFraOgMed{ get;}
    @TestVisible
    public Date gyldigTilOgMed{ get;}
    public PDL_Metadata metadata{ get;}

    public PDL_Fullmakt() {

    }
}
