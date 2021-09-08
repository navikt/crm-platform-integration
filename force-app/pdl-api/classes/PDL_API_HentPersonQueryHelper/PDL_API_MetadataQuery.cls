public with sharing class PDL_API_MetadataQuery {

    public Boolean opplysningsId = false;
    public Boolean master = false;
    PDL_API_EndringQuery endringer;
    public Boolean historisk = false;

    public PDL_API_MetadataQuery() {
        endringer = new PDL_API_EndringQuery();
    }

    public void selectAll(){
        opplysningsId = true;
        master = true;
        endringer.selectAll();
        historisk = true;
    }

    public Boolean isEmpty(){
        return !(   opplysningsId || 
                    master || 
                    !endringer.isEmpty() || 
                    historisk );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( opplysningsId ) selectionSet.addItem( new GQLField( 'opplysningsId' ) );
        if ( master ) selectionSet.addItem( new GQLField( 'master' ) );
        selectionSet.addItem( endringer.buildGQLField() );
        if ( historisk ) selectionSet.addItem( new GQLField( 'historisk' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'metadata',
            args,
            selectionSet
        );
    }
}
