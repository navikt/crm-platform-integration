public with sharing class PDL_API_IdentitetsgrunnlagQuery {

    public Boolean historikk = false;

    public Boolean status = false;

    PDL_API_FolkeregistermetadataQuery folkeregistermetadata;
    PDL_API_MetadataQuery metadata;

    public PDL_API_IdentitetsgrunnlagQuery() {
        folkeregistermetadata = new PDL_API_FolkeregistermetadataQuery();
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        status = true;
    }

    public void selectAll(Boolean includeMetadata){
        if(includeMetadata){
            folkeregistermetadata.selectAll();
            metadata.selectAll();
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   status ||
                    !folkeregistermetadata.isEmpty() || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( status ) selectionSet.addItem( new GQLField( 'status' ) );
        selectionSet.addItem( folkeregistermetadata.buildGQLField() );
        selectionSet.addItem( metadata.buildGQLField() );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'identitetsgrunnlag',
            args,
            selectionSet
        );
    }
}
