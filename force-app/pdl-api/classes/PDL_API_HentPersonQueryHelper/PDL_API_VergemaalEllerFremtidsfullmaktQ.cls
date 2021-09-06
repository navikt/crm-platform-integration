public with sharing class PDL_API_VergemaalEllerFremtidsfullmaktQ {

    public Boolean historikk = false;

    public Boolean type = false;
    public Boolean embete = false;
    public Boolean vergeEllerFullmektig = false;

    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_VergemaalEllerFremtidsfullmaktQ() {

    }

    public Boolean isEmpty(){
        return !(   type ||
                    embete ||
                    vergeEllerFullmektig ||
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( type ) selectionSet.addItem( new GQLField( 'type' ) );
        if ( embete ) selectionSet.addItem( new GQLField( 'embete' ) );
        if ( vergeEllerFullmektig ) selectionSet.addItem( new GQLField( 'vergeEllerFullmektig' ) );
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'vergemaalEllerFremtidsfullmakt',
            args,
            selectionSet
        );
    }
}
