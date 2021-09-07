public with sharing class PDL_API_DoedsfallQuery {

    public Boolean doedsdato = false;

    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_DoedsfallQuery() {

    }

    public void selectAll(){
        doedsdato = true;
    }

    public void selectAll(Boolean metadata){
        if(metadata){
            folkeregistermetadata = true;
            metadata = true;
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   doedsdato ||
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( doedsdato ) selectionSet.addItem( new GQLField( 'doedsdato' ) );
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'doedsfall',
            args,
            selectionSet
        );
    }
}
