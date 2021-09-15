public with sharing class PDL_Person {
    @TestVisible
    public List<PDL_Navn> navn { get; private set; }
    @TestVisible
    public List<PDL_FolkeregisterIdentifikator> folkeregisterIdentifikator { get; private set; }
    @TestVisible
    public List<PDL_Sivilstand> sivilstand { get; private set; }
    @TestVisible
    public List<PDL_InnflyttingTilNorge> innflyttingTilNorge { get; private set; }
    @TestVisible
    public List<PDL_UtflyttingFraNorge> utflyttingFraNorge { get; private set; }
}
