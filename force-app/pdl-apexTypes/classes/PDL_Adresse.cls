public virtual with sharing class PDL_Adresse {
    @TestVisible
    public Long matrikkelId { get; }
    @TestVisible
    public String bruksenhetsnummer { get; }
    public String kommunenummer { get; }
    public String bydelsnummer { get; }
    public String tilleggsnavn { get; }
    public String postnummer { get; }
    public PDL_Koordinater koordinater { get; }

    public PDL_Adresse() {
    }
}
