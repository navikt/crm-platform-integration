public with sharing class PDL_API_UtenlandskIdentifikasjonsnummerQ {

    public Boolean historikk = false;

    public Boolean identifikasjonsnummer = false;
    public Boolean utstederland = false;
    public Boolean opphoert = false;

    PDL_API_FolkeregistermetadataQuery folkeregistermetadata;
    PDL_API_MetadataQuery metadata;

    public PDL_API_UtenlandskIdentifikasjonsnummerQ() {
        folkeregistermetadata = new PDL_API_FolkeregistermetadataQuery();
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        identifikasjonsnummer = true;
        utstederland = true;
        opphoert = true;
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
                    utstederland ||
                    opphoert ||
                    !folkeregistermetadata.isEmpty() || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( identifikasjonsnummer ) selectionSet.addItem( new GQLField( 'identifikasjonsnummer' ) );
        if ( utstederland ) selectionSet.addItem( new GQLField( 'utstederland' ) );
        if ( opphoert ) selectionSet.addItem( new GQLField( 'opphoert' ) );
        selectionSet.addItem( folkeregistermetadata.buildGQLField() );
        selectionSet.addItem( metadata.buildGQLField() );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'utenlandskIdentifikasjonsnummer',
            args,
            selectionSet
        );
    }
}
