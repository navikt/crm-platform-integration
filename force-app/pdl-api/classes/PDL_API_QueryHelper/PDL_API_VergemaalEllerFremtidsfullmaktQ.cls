public with sharing class PDL_API_VergemaalEllerFremtidsfullmaktQ {

    public Boolean historikk = false;

    public Boolean type = false;
    public Boolean embete = false;
    PDL_API_VergeEllerFullmektigQuery vergeEllerFullmektig;

    PDL_API_FolkeregistermetadataQuery folkeregistermetadata;
    PDL_API_MetadataQuery metadata;

    public PDL_API_VergemaalEllerFremtidsfullmaktQ() {
        vergeEllerFullmektig = new PDL_API_VergeEllerFullmektigQuery();
        folkeregistermetadata = new PDL_API_FolkeregistermetadataQuery();
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        type = true;
        embete = true;
        vergeEllerFullmektig.selectAll();
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
                    embete ||
                    !vergeEllerFullmektig.isEmpty() ||
                    !folkeregistermetadata.isEmpty() || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( type ) selectionSet.addItem( new GQLField( 'type' ) );
        if ( embete ) selectionSet.addItem( new GQLField( 'embete' ) );
        selectionSet.addItem( vergeEllerFullmektig.buildGQLField() );
        selectionSet.addItem( folkeregistermetadata.buildGQLField() );
        selectionSet.addItem( metadata.buildGQLField() );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'vergemaalEllerFremtidsfullmakt',
            args,
            selectionSet
        );
    }
}
