public with sharing class PDL_API_StatsborgerskapQuery {

    public Boolean historikk = false;

    public Boolean land = false;
    public Boolean bekreftelsesdato = false;
    public Boolean gyldigFraOgMed = false;
    public Boolean gyldigTilOgMed = false;

    PDL_API_FolkeregistermetadataQuery folkeregistermetadata;
    PDL_API_MetadataQuery metadata;

    public PDL_API_StatsborgerskapQuery() {
        folkeregistermetadata = new PDL_API_FolkeregistermetadataQuery();
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        land = true;
        bekreftelsesdato = true;
        gyldigFraOgMed = true;
        gyldigTilOgMed = true;
    }

    public void selectAll(Boolean includeMetadata){
        if(includeMetadata){
            folkeregistermetadata.selectAll();
            metadata.selectAll();
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   land ||
                    bekreftelsesdato ||
                    gyldigFraOgMed ||
                    gyldigTilOgMed ||
                    !folkeregistermetadata.isEmpty() || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( land ) selectionSet.addItem( new GQLField( 'land' ) );
        if ( bekreftelsesdato ) selectionSet.addItem( new GQLField( 'bekreftelsesdato' ) );
        if ( gyldigFraOgMed ) selectionSet.addItem( new GQLField( 'gyldigFraOgMed' ) );
        if ( gyldigTilOgMed ) selectionSet.addItem( new GQLField( 'gyldigTilOgMed' ) );
        selectionSet.addItem( folkeregistermetadata.buildGQLField() );
        selectionSet.addItem( metadata.buildGQLField() );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'statsborgerskap',
            args,
            selectionSet
        );
    }
}
