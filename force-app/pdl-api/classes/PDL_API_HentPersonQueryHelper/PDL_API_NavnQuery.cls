public with sharing class PDL_API_NavnQuery {
    public Boolean historikk = false;
    public Boolean fornavn = false;
    public Boolean mellomnavn = false;
    public Boolean etternavn = false;
    public Boolean forkortetNavn = false;
    public Boolean originaltNavn = false;
    public Boolean gyldigFraOgMed = false;

    Boolean folkeregistermetadata = false;
    Boolean metadata = false;

    public PDL_API_NavnQuery() {

    }

    public Boolean isEmpty(){
        return !(   fornavn || 
                    mellomnavn || 
                    etternavn || 
                    forkortetNavn ||
                    gyldigFraOgMed || 
                    originaltNavn ||
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( fornavn ) selectionSet.addItem( new GQLField( 'fornavn' ) );
        if ( mellomnavn ) selectionSet.addItem( new GQLField( 'mellomnavn' ) );
        if ( etternavn ) selectionSet.addItem( new GQLField( 'etternavn' ) );
        if ( forkortetNavn ) selectionSet.addItem( new GQLField( 'forkortetNavn' ) );
        if ( originaltNavn ) selectionSet.addItem( new GQLField( 'originaltNavn' ) );
        if ( gyldigFraOgMed ) selectionSet.addItem( new GQLField( 'gyldigFraOgMed' ) );
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'navn',
            args,
            selectionSet
        );
    }
}
