public with sharing class PdlFullmakt extends PdlObject {
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

    public PdlFullmakt() {
    }
}
