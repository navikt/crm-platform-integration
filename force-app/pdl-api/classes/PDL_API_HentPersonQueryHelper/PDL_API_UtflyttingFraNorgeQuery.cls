public with sharing class PDL_API_UtflyttingFraNorgeQuery {

    public Boolean historikk = false;

    public Boolean tilflyttingsland = false;
    public Boolean tilflyttingsstedIUtlandet = false;
    public Boolean utflyttingsdato = false;

    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_UtflyttingFraNorgeQuery() {

    }

    public Boolean isEmpty(){
        return !(   tilflyttingsland ||
                    tilflyttingsstedIUtlandet ||
                    utflyttingsdato ||
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( tilflyttingsland ) selectionSet.addItem( new GQLField( 'tilflyttingsland' ) );
        if ( tilflyttingsstedIUtlandet ) selectionSet.addItem( new GQLField( 'tilflyttingsstedIUtlandet' ) );
        if ( utflyttingsdato ) selectionSet.addItem( new GQLField( 'utflyttingsdato' ) );
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'utflyttingFraNorge',
            args,
            selectionSet
        );
    }
}
