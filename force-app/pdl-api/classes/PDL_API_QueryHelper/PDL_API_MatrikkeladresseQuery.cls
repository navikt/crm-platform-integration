public with sharing class PDL_API_MatrikkeladresseQuery {
    public Boolean matrikkelId = false;
    public Boolean bruksenhetsnummer = false;
    public Boolean kommunenummer = false;
    public Boolean tilleggsnavn = false;
    public Boolean postnummer = false;
    PDL_API_KoordinaterQuery koordinater;
    
    public PDL_API_MatrikkeladresseQuery() {
        koordinater = new PDL_API_KoordinaterQuery();
    }

    public void selectAll(){
        matrikkelId = true;
        bruksenhetsnummer = true;
        kommunenummer = true;
        tilleggsnavn = true;
        postnummer = true;
        koordinater.selectAll();
    }

    public Boolean isEmpty(){
        return !(   matrikkelId ||
                    bruksenhetsnummer ||
                    kommunenummer ||
                    tilleggsnavn ||
                    postnummer||
                    !koordinater.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( matrikkelId ) selectionSet.addItem( new GQLField( 'matrikkelId' ) );
        if ( bruksenhetsnummer ) selectionSet.addItem( new GQLField( 'bruksenhetsnummer' ) );
        if ( kommunenummer ) selectionSet.addItem( new GQLField( 'kommunenummer' ) );
        if ( tilleggsnavn ) selectionSet.addItem( new GQLField( 'tilleggsnavn' ) );
        if ( postnummer ) selectionSet.addItem( new GQLField( 'postnummer' ) );
        selectionSet.addItem( koordinater.buildGQLField() );
        
        GQLArguments args = new GQLArguments();

        return new GQLField(
            'matrikkeladresse',
            args,
            selectionSet
        );
    }
}
