public with sharing class PDL_API_AdressebeskyttelseQuery {
    public Boolean historikk = false;

    public Boolean gradering = false;

    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_AdressebeskyttelseQuery() {

    }

    public Boolean isEmpty(){
        return !(   gradering || 
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( gradering ) selectionSet.addItem( new GQLField( 'gradering' ) );
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'adressebeskyttelse',
            args,
            selectionSet
        );
    }
}
