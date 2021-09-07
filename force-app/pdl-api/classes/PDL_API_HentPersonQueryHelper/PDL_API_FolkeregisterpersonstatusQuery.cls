public with sharing class PDL_API_FolkeregisterpersonstatusQuery {

    public Boolean historikk = false;

    public Boolean status = false;
    public Boolean forenkletStatus = false;

    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_FolkeregisterpersonstatusQuery() {

    }

    public void selectAll(){
        status = true;
        forenkletStatus = true;
    }

    public void selectAll(Boolean metadata){
        if(metadata){
            folkeregistermetadata = true;
            metadata = true;
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   status ||
                    forenkletStatus ||
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( status ) selectionSet.addItem( new GQLField( 'status' ) );
        if ( forenkletStatus ) selectionSet.addItem( new GQLField( 'forenkletStatus' ) );
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'folkeregisterpersonstatus',
            args,
            selectionSet
        );
    }
}
