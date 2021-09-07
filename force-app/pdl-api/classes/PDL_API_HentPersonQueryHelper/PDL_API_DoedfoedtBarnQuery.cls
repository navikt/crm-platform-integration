public with sharing class PDL_API_DoedfoedtBarnQuery {
    
    public Boolean dato = false;

    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_DoedfoedtBarnQuery() {

    }

    public void selectAll(){
        dato = true;
    }

    public void selectAll(Boolean metadata){
        if(metadata){
            folkeregistermetadata = true;
            metadata = true;
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   dato ||
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( dato ) selectionSet.addItem( new GQLField( 'dato' ) );
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'doedfoedtBarn',
            args,
            selectionSet
        );
    }
}
