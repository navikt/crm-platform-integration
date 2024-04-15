public with sharing class PdlStatsborgerskap extends PdlObject {
    @TestVisible
    public String land{ get;}
    public Date bekreftelsesdato{ get;}
    public Date gyldigFraOgMed{ get;}
    public Date gyldigTilOgMed{ get;}
    public PDL_Folkeregistermetadata folkeregistermetadata{ get;}

    public PdlStatsborgerskap() {
    }
}
