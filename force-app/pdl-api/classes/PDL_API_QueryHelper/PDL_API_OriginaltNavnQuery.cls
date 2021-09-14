public with sharing class PDL_API_OriginaltNavnQuery {

    public Boolean fornavn = false;
    public Boolean mellomnavn = false;
    public Boolean etternavn = false;

    public PDL_API_OriginaltNavnQuery() {

    }
    public void selectAll(){
        fornavn = true;
        mellomnavn = true;
        etternavn = true;
    }

    public Boolean isEmpty(){
        return !(   fornavn || 
                    mellomnavn || 
                    etternavn );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( fornavn ) selectionSet.addItem( new GQLField( 'fornavn' ) );
        if ( mellomnavn ) selectionSet.addItem( new GQLField( 'mellomnavn' ) );
        if ( etternavn ) selectionSet.addItem( new GQLField( 'etternavn' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'originaltNavn',
            args,
            selectionSet
        );
    }
}
