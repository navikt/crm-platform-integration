public with sharing class PDL_API_TolkQuery {

    public Boolean spraak = false;
    private String fieldName = 'tolk';

    public PDL_API_TolkQuery() {

    }

    public PDL_API_TolkQuery(String fieldName) {
        this.fieldName = fieldName;
    }
    
    public void selectAll(){
        spraak = true;
    }

    public Boolean isEmpty(){
        return !( spraak );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( spraak ) selectionSet.addItem( new GQLField( 'spraak' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            fieldName,
            args,
            selectionSet
        );
    }
}
