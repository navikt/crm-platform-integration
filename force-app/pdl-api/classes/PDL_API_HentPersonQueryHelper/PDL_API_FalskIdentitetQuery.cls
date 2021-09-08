public with sharing class PDL_API_FalskIdentitetQuery {
    public Boolean erFalsk = false;
    public Boolean rettIdentitetVedIdentifikasjonsnummer = false;
    public Boolean rettIdentitetErUkjent = false;
    PDL_API_FalskIdIdentifiserendeInfoQuery rettIdentitetVedOpplysninger;

    PDL_API_FolkeregistermetadataQuery folkeregistermetadata;
    PDL_API_MetadataQuery metadata;

    public PDL_API_FalskIdentitetQuery() {
        rettIdentitetVedOpplysninger = new PDL_API_FalskIdIdentifiserendeInfoQuery();
        folkeregistermetadata = new PDL_API_FolkeregistermetadataQuery();
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        erFalsk = true;
        rettIdentitetVedIdentifikasjonsnummer = true;
        rettIdentitetErUkjent = true;
        rettIdentitetVedOpplysninger.selectAll();
    }

    public void selectAll(Boolean includeMetadata){
        if(includeMetadata){
            folkeregistermetadata.selectAll();
            metadata.selectAll();
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   erFalsk ||
                    rettIdentitetVedIdentifikasjonsnummer ||
                    rettIdentitetErUkjent ||
                    !rettIdentitetVedOpplysninger.isEmpty() ||
                    !folkeregistermetadata.isEmpty() || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( erFalsk ) selectionSet.addItem( new GQLField( 'erFalsk' ) );
        if ( rettIdentitetVedIdentifikasjonsnummer ) selectionSet.addItem( new GQLField( 'rettIdentitetVedIdentifikasjonsnummer' ) );
        if ( rettIdentitetErUkjent ) selectionSet.addItem( new GQLField( 'rettIdentitetErUkjent' ) );
        selectionSet.addItem( rettIdentitetVedOpplysninger.buildGQLField() );
        selectionSet.addItem( folkeregistermetadata.buildGQLField() );
        selectionSet.addItem( metadata.buildGQLField() );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'falskIdentitet',
            args,
            selectionSet
        );
    }
}
