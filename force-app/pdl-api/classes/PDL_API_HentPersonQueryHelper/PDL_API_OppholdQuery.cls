public with sharing class PDL_API_OppholdQuery {

    public Boolean historikk = false;

    public Boolean type = false;
    public Boolean oppholdFra = false;
    public Boolean oppholdTil = false;

    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_OppholdQuery() {

    }

    public void selectAll(){
        type = true;
        oppholdFra = true;
        oppholdTil = true;
    }

    public void selectAll(Boolean metadata){
        if(metadata){
            folkeregistermetadata = true;
            metadata = true;
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   type ||
                    oppholdFra ||
                    oppholdTil ||
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( type ) selectionSet.addItem( new GQLField( 'type' ) );
        if ( oppholdFra ) selectionSet.addItem( new GQLField( 'oppholdFra' ) );
        if ( oppholdTil ) selectionSet.addItem( new GQLField( 'oppholdTil' ) );
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'opphold',
            args,
            selectionSet
        );
    }
}
