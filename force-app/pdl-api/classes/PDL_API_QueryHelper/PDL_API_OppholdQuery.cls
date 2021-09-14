public with sharing class PDL_API_OppholdQuery {

    public Boolean historikk = false;

    public Boolean type = false;
    public Boolean oppholdFra = false;
    public Boolean oppholdTil = false;

    PDL_API_FolkeregistermetadataQuery folkeregistermetadata;
    PDL_API_MetadataQuery metadata;

    public PDL_API_OppholdQuery() {
        folkeregistermetadata = new PDL_API_FolkeregistermetadataQuery();
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        type = true;
        oppholdFra = true;
        oppholdTil = true;
    }

    public void selectAll(Boolean includeMetadata){
        if(includeMetadata){
            folkeregistermetadata.selectAll();
            metadata.selectAll();
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   type ||
                    oppholdFra ||
                    oppholdTil ||
                    !folkeregistermetadata.isEmpty() || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( type ) selectionSet.addItem( new GQLField( 'type' ) );
        if ( oppholdFra ) selectionSet.addItem( new GQLField( 'oppholdFra' ) );
        if ( oppholdTil ) selectionSet.addItem( new GQLField( 'oppholdTil' ) );
        selectionSet.addItem( folkeregistermetadata.buildGQLField() );
        selectionSet.addItem( metadata.buildGQLField() );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'opphold',
            args,
            selectionSet
        );
    }
}
