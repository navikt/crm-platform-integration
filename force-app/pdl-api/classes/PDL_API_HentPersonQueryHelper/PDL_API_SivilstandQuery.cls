public with sharing class PDL_API_SivilstandQuery {

    public Boolean historikk = false;

    public Boolean type = false;
    public Boolean gyldigFraOgMed = false;
    public Boolean relatertVedSivilstand = false;
    public Boolean bekreftelsesdato = false;

    PDL_API_FolkeregistermetadataQuery folkeregistermetadata;
    PDL_API_MetadataQuery metadata;

    public PDL_API_SivilstandQuery() {
        folkeregistermetadata = new PDL_API_FolkeregistermetadataQuery();
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        type = true;
        gyldigFraOgMed = true;
        relatertVedSivilstand = true;
        bekreftelsesdato = true;
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
                    gyldigFraOgMed ||
                    relatertVedSivilstand ||
                    bekreftelsesdato ||
                    !folkeregistermetadata.isEmpty() || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( type ) selectionSet.addItem( new GQLField( 'type' ) );
        if ( gyldigFraOgMed ) selectionSet.addItem( new GQLField( 'gyldigFraOgMed' ) );
        if ( relatertVedSivilstand ) selectionSet.addItem( new GQLField( 'relatertVedSivilstand' ) );
        if ( bekreftelsesdato ) selectionSet.addItem( new GQLField( 'bekreftelsesdato' ) );
        selectionSet.addItem( folkeregistermetadata.buildGQLField() );
        selectionSet.addItem( metadata.buildGQLField() );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'sivilstand',
            args,
            selectionSet
        );
    }
}
