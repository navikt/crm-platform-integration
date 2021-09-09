public with sharing class PDL_API_InnflyttingTilNorgeQuery {

    public Boolean fraflyttingsland = false;
    public Boolean fraflyttingsstedIUtlandet = false;

    PDL_API_FolkeregistermetadataQuery folkeregistermetadata;
    PDL_API_MetadataQuery metadata;

    public PDL_API_InnflyttingTilNorgeQuery() {
        folkeregistermetadata = new PDL_API_FolkeregistermetadataQuery();
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        fraflyttingsland = true;
        fraflyttingsstedIUtlandet = true;
    }

    public void selectAll(Boolean includeMetadata){
        if(includeMetadata){
            folkeregistermetadata.selectAll();
            metadata.selectAll();
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   fraflyttingsland ||
                    fraflyttingsstedIUtlandet ||
                    !folkeregistermetadata.isEmpty() || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( fraflyttingsland ) selectionSet.addItem( new GQLField( 'fraflyttingsland' ) );
        if ( fraflyttingsstedIUtlandet ) selectionSet.addItem( new GQLField( 'fraflyttingsstedIUtlandet' ) );
        selectionSet.addItem( folkeregistermetadata.buildGQLField() );
        selectionSet.addItem( metadata.buildGQLField() );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'innflyttingTilNorge',
            args,
            selectionSet
        );
    }
}
