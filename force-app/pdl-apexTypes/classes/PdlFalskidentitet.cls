public with sharing class PdlFalskidentitet extends PdlObject {
    public Boolean erFalsk{ get;}
    public String rettIdentitetVedIdentifikasjonsnummer{ get;}
    public Boolean rettIdentitetErUkjent{ get;}
    public PDL_FalskIdentitetIdentifiserendeInfo rettIdentitetVedOpplysninger{ get;}
    public PDL_Folkeregistermetadata folkeregistermetadata{ get;}

    public PdlFalskidentitet() {
    }
}
