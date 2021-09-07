public with sharing class PDL_API_KjoennQuery {

    public Boolean historikk = false;

    public Boolean kjoenn = false;

    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_KjoennQuery() {

    }

    public void selectAll(){
        kjoenn = true;
    }

    public void selectAll(Boolean metadata){
        if(metadata){
            folkeregistermetadata = true;
            metadata = true;
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   kjoenn ||
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( kjoenn ) selectionSet.addItem( new GQLField( 'kjoenn' ) );
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'kjoenn',
            args,
            selectionSet
        );
    }
}
