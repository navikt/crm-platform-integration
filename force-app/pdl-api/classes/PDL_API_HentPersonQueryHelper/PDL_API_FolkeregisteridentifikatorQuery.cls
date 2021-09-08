public with sharing class PDL_API_FolkeregisteridentifikatorQuery {

    public Boolean historikk = false;

    public Boolean identifikasjonsnummer = false;
    public Boolean status = false;
    public Boolean type = false;

    PDL_API_FolkeregistermetadataQuery folkeregistermetadata;
    PDL_API_MetadataQuery metadata;

    public PDL_API_FolkeregisteridentifikatorQuery() {
        folkeregistermetadata = new PDL_API_FolkeregistermetadataQuery();
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        identifikasjonsnummer = true;
        status = true;
        type = true;
    }

    public void selectAll(Boolean includeMetadata){
        if(includeMetadata){
            folkeregistermetadata.selectAll();
            metadata.selectAll();
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   identifikasjonsnummer ||
                    status ||
                    type ||
                    !folkeregistermetadata.isEmpty() || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( identifikasjonsnummer ) selectionSet.addItem( new GQLField( 'identifikasjonsnummer' ) );
        if ( status ) selectionSet.addItem( new GQLField( 'status' ) );
        if ( type ) selectionSet.addItem( new GQLField( 'type' ) );
        selectionSet.addItem( folkeregistermetadata.buildGQLField() );
        selectionSet.addItem( metadata.buildGQLField() );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'folkeregisteridentifikator',
            args,
            selectionSet
        );
    }
}
