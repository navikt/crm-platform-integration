public with sharing class PDL_API_FolkeregisteridentifikatorQuery {

    public Boolean historikk = false;

    public Boolean identifikasjonsnummer = false;
    public Boolean status = false;
    public Boolean type = false;

    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_FolkeregisteridentifikatorQuery() {

    }

    public Boolean isEmpty(){
        return !(   identifikasjonsnummer ||
                    status ||
                    type ||
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( identifikasjonsnummer ) selectionSet.addItem( new GQLField( 'identifikasjonsnummer' ) );
        if ( status ) selectionSet.addItem( new GQLField( 'status' ) );
        if ( type ) selectionSet.addItem( new GQLField( 'type' ) );
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'folkeregisteridentifikator',
            args,
            selectionSet
        );
    }
}
