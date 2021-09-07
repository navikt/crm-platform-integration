public with sharing class PDL_API_TilrettelagtKommunikasjonQuery {

    public Boolean talespraaktolk = false;
    public Boolean tegnspraaktolk = false;

    public Boolean metadata = false;

    public PDL_API_TilrettelagtKommunikasjonQuery() {

    }

    public void selectAll(){
        talespraaktolk = true;
        tegnspraaktolk = true;
    }

    public void selectAll(Boolean metadata){
        if(metadata){
            metadata = true;
        }
        selectAll();
    }
    
    public Boolean isEmpty(){
        return !(   talespraaktolk ||
                    tegnspraaktolk || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( talespraaktolk ) selectionSet.addItem( new GQLField( 'talespraaktolk' ) );
        if ( tegnspraaktolk ) selectionSet.addItem( new GQLField( 'tegnspraaktolk' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'tilrettelagtKommunikasjon',
            args,
            selectionSet
        );
    }
}
