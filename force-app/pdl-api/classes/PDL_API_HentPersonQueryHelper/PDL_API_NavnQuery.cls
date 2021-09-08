public with sharing class PDL_API_NavnQuery {
   
    public Boolean historikk = false;

    public Boolean fornavn = false;
    public Boolean mellomnavn = false;
    public Boolean etternavn = false;
    public Boolean forkortetNavn = false;
    PDL_API_OriginaltNavnQuery originaltNavn;
    public Boolean gyldigFraOgMed = false;

    PDL_API_FolkeregistermetadataQuery folkeregistermetadata;
    PDL_API_MetadataQuery metadata;

    public PDL_API_NavnQuery() {
        originaltNavn = new PDL_API_OriginaltNavnQuery();
        folkeregistermetadata = new PDL_API_FolkeregistermetadataQuery();
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        fornavn = true;
        mellomnavn = true;
        etternavn = true;
        forkortetNavn = true;
        originaltNavn.selectAll();
        gyldigFraOgMed = true;
    }

    public void selectAll(Boolean includeMetadata){
        if(includeMetadata){
            folkeregistermetadata.selectAll();
            metadata.selectAll();
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   fornavn || 
                    mellomnavn || 
                    etternavn || 
                    forkortetNavn ||
                    gyldigFraOgMed || 
                    !originaltNavn.isEmpty() ||
                    !folkeregistermetadata.isEmpty() || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( fornavn ) selectionSet.addItem( new GQLField( 'fornavn' ) );
        if ( mellomnavn ) selectionSet.addItem( new GQLField( 'mellomnavn' ) );
        if ( etternavn ) selectionSet.addItem( new GQLField( 'etternavn' ) );
        if ( forkortetNavn ) selectionSet.addItem( new GQLField( 'forkortetNavn' ) );
        selectionSet.addItem( originaltNavn.buildGQLField() );
        if ( gyldigFraOgMed ) selectionSet.addItem( new GQLField( 'gyldigFraOgMed' ) );
        selectionSet.addItem( folkeregistermetadata.buildGQLField() );
        selectionSet.addItem( metadata.buildGQLField() );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'navn',
            args,
            selectionSet
        );
    }
}
