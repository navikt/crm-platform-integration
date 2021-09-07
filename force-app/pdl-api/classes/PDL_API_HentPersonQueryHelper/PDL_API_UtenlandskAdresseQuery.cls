public with sharing class PDL_API_UtenlandskAdresseQuery {
    public Boolean adressenavnNummer = false;
    public Boolean bygningEtasjeLeilighet = false;
    public Boolean postboksNummerNavn = false;
    public Boolean postkode = false;
    public Boolean bySted = false;
    public Boolean regionDistriktOmraade = false;
    public Boolean landkode = false;

    public PDL_API_UtenlandskAdresseQuery() {

    }

    public void selectAll(){
        adressenavnNummer = true;
        bygningEtasjeLeilighet = true;
        postboksNummerNavn = true;
        postkode = true;
        bySted = true;
        regionDistriktOmraade = true;
        landkode = true;
    }

    public Boolean isEmpty(){
        return !(   adressenavnNummer || 
                    bygningEtasjeLeilighet || 
                    postboksNummerNavn || 
                    postkode ||
                    bySted || 
                    regionDistriktOmraade ||
                    landkode );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( adressenavnNummer ) selectionSet.addItem( new GQLField( 'adressenavnNummer' ) );
        if ( bygningEtasjeLeilighet ) selectionSet.addItem( new GQLField( 'bygningEtasjeLeilighet' ) );
        if ( postboksNummerNavn ) selectionSet.addItem( new GQLField( 'postboksNummerNavn' ) );
        if ( postkode ) selectionSet.addItem( new GQLField( 'postkode' ) );
        if ( bySted ) selectionSet.addItem( new GQLField( 'bySted' ) );
        if ( regionDistriktOmraade ) selectionSet.addItem( new GQLField( 'regionDistriktOmraade' ) );
        if ( landkode ) selectionSet.addItem( new GQLField( 'landkode' ) );
        
        GQLArguments args = new GQLArguments();

        return new GQLField(
            'utenlandskAdresse',
            args,
            selectionSet
        );
    }
}
