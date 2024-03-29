public with sharing class PDL_API_VegadresseQuery {
    public Boolean matrikkelId = false;
    public Boolean husnummer = false;
    public Boolean husbokstav = false;
    public Boolean bruksenhetsnummer = false;
    public Boolean adressenavn = false;
    public Boolean kommunenummer = false;
    public Boolean bydelsnummer = false;
    public Boolean tilleggsnavn = false;
    public Boolean postnummer = false;
    PDL_API_KoordinaterQuery koordinater;

    public PDL_API_VegadresseQuery() {
        koordinater = new PDL_API_KoordinaterQuery();
    }

    public void selectAll(){
        matrikkelId = true;
        husnummer = true;
        husbokstav = true;
        bruksenhetsnummer = true;
        adressenavn = true;
        kommunenummer = true;
        bydelsnummer = true;
        tilleggsnavn = true;
        postnummer = true;
        koordinater.selectAll();
    }

    public Boolean isEmpty(){
        return !(   matrikkelId || 
                    husnummer || 
                    husbokstav || 
                    bruksenhetsnummer ||
                    adressenavn || 
                    kommunenummer ||
                    bydelsnummer || 
                    tilleggsnavn ||
                    postnummer ||
                    !koordinater.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( matrikkelId ) selectionSet.addItem( new GQLField( 'matrikkelId' ) );
        if ( husnummer ) selectionSet.addItem( new GQLField( 'husnummer' ) );
        if ( husbokstav ) selectionSet.addItem( new GQLField( 'husbokstav' ) );
        if ( bruksenhetsnummer ) selectionSet.addItem( new GQLField( 'bruksenhetsnummer' ) );
        if ( adressenavn ) selectionSet.addItem( new GQLField( 'adressenavn' ) );
        if ( kommunenummer ) selectionSet.addItem( new GQLField( 'kommunenummer' ) );
        if ( bydelsnummer ) selectionSet.addItem( new GQLField( 'bydelsnummer' ) );
        if ( tilleggsnavn ) selectionSet.addItem( new GQLField( 'tilleggsnavn' ) );
        if ( postnummer ) selectionSet.addItem( new GQLField( 'postnummer' ) );
        selectionSet.addItem( koordinater.buildGQLField() );
        
        GQLArguments args = new GQLArguments();

        return new GQLField(
            'vegadresse',
            args,
            selectionSet
        );
    }
}
