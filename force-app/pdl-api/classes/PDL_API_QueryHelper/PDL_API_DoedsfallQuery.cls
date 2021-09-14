public with sharing class PDL_API_DoedsfallQuery {

    public Boolean doedsdato = false;

    PDL_API_FolkeregistermetadataQuery folkeregistermetadata;
    PDL_API_MetadataQuery metadata;

    public PDL_API_DoedsfallQuery() {
        folkeregistermetadata = new PDL_API_FolkeregistermetadataQuery();
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        doedsdato = true;
    }

    public void selectAll(Boolean includeMetadata){
        if(includeMetadata){
            folkeregistermetadata.selectAll();
            metadata.selectAll();
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   doedsdato ||
                    !folkeregistermetadata.isEmpty() || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( doedsdato ) selectionSet.addItem( new GQLField( 'doedsdato' ) );
        selectionSet.addItem( folkeregistermetadata.buildGQLField() );
        selectionSet.addItem( metadata.buildGQLField() );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'doedsfall',
            args,
            selectionSet
        );
    }
}
