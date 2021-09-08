public with sharing class PDL_API_PersonnavnQuery {

    public Boolean fornavn = false;
    public Boolean mellomnavn = false;
    public Boolean etternavn = false;
    private String fieldName = 'personnavn';

    public PDL_API_PersonnavnQuery() {

    }
    public PDL_API_PersonnavnQuery(String fieldName) {
        this.fieldName = fieldName;
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
            fieldName,
            args,
            selectionSet
        );
    }
}
