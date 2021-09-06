public with sharing class PDL_API_InnflyttingTilNorgeQuery {

    public Boolean historikk = false;

    public Boolean fraflyttingsland = false;
    public Boolean fraflyttingsstedIUtlandet = false;

    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_InnflyttingTilNorgeQuery() {

    }

    public Boolean isEmpty(){
        return !(   fraflyttingsland ||
                    fraflyttingsstedIUtlandet ||
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( fraflyttingsland ) selectionSet.addItem( new GQLField( 'fraflyttingsland' ) );
        if ( fraflyttingsstedIUtlandet ) selectionSet.addItem( new GQLField( 'fraflyttingsstedIUtlandet' ) );
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'innflyttingTilNorge',
            args,
            selectionSet
        );
    }
}
