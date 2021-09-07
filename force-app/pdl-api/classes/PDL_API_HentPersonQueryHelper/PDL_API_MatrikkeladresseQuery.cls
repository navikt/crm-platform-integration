public with sharing class PDL_API_MatrikkeladresseQuery {
    public Boolean matrikkelId = false;
    public Boolean bruksenhetsnummer = false;
    public Boolean kommunenummer = false;
    public Boolean tilleggsnavn = false;
    public Boolean postnummer = false;
    public Boolean koordinater = false;
    
    public PDL_API_MatrikkeladresseQuery() {

    }

    public void selectAll(){
        matrikkelId = true;
        bruksenhetsnummer = true;
        kommunenummer = true;
        tilleggsnavn = true;
        postnummer = true;
        koordinater = true;
    }

    public Boolean isEmpty(){
        return !(   matrikkelId ||
                    bruksenhetsnummer ||
                    kommunenummer ||
                    tilleggsnavn ||
                    postnummer||
                    koordinater );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( matrikkelId ) selectionSet.addItem( new GQLField( 'matrikkelId' ) );
        if ( bruksenhetsnummer ) selectionSet.addItem( new GQLField( 'bruksenhetsnummer' ) );
        if ( kommunenummer ) selectionSet.addItem( new GQLField( 'kommunenummer' ) );
        if ( tilleggsnavn ) selectionSet.addItem( new GQLField( 'tilleggsnavn' ) );
        if ( postnummer ) selectionSet.addItem( new GQLField( 'postnummer' ) );
        if ( koordinater ) selectionSet.addItem( new GQLField( 'koordinater' ) );
        
        GQLArguments args = new GQLArguments();

        return new GQLField(
            'matrikkeladresse',
            args,
            selectionSet
        );
    }
}
