public with sharing class PDL_API_TilrettelagtKommunikasjonQuery {

    PDL_API_TolkQuery talespraaktolk;
    PDL_API_TolkQuery tegnspraaktolk;

    PDL_API_MetadataQuery metadata;

    public PDL_API_TilrettelagtKommunikasjonQuery() {
        talespraaktolk = new PDL_API_TolkQuery('talespraaktolk');
        tegnspraaktolk = new PDL_API_TolkQuery('tegnspraaktolk');
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        talespraaktolk.selectAll();
        tegnspraaktolk.selectAll();
    }

    public void selectAll(Boolean includeMetadata){
        if(includeMetadata){
            metadata.selectAll();
        }
        selectAll();
    }
    
    public Boolean isEmpty(){
        return !(   !talespraaktolk.isEmpty() ||
                    !tegnspraaktolk.isEmpty() || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        selectionSet.addItem( talespraaktolk.buildGQLField() );
        selectionSet.addItem( tegnspraaktolk.buildGQLField() );
        selectionSet.addItem( metadata.buildGQLField() );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'tilrettelagtKommunikasjon',
            args,
            selectionSet
        );
    }
}
