public with sharing class PDL_API_FullmaktQuery {

    public Boolean historikk = false;

    public Boolean motpartsPersonident = false;
    public Boolean motpartsRolle = false;
    public Boolean omraader = false;
    public Boolean gyldigFraOgMed = false;
    public Boolean gyldigTilOgMed = false;

    PDL_API_MetadataQuery metadata;

    public PDL_API_FullmaktQuery() {
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        motpartsPersonident = true;
        motpartsRolle = true;
        omraader = true;
        gyldigFraOgMed = true;
        gyldigTilOgMed = true;
    }

    public void selectAll(Boolean includeMetadata){
        if(includeMetadata){
            metadata.selectAll();
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   motpartsPersonident ||
                    motpartsRolle ||
                    omraader ||
                    gyldigFraOgMed ||
                    gyldigTilOgMed || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( motpartsPersonident ) selectionSet.addItem( new GQLField( 'motpartsPersonident' ) );
        if ( motpartsRolle ) selectionSet.addItem( new GQLField( 'motpartsRolle' ) );
        if ( omraader ) selectionSet.addItem( new GQLField( 'omraader' ) );
        if ( gyldigFraOgMed ) selectionSet.addItem( new GQLField( 'gyldigFraOgMed' ) );
        if ( gyldigTilOgMed ) selectionSet.addItem( new GQLField( 'gyldigTilOgMed' ) );
        selectionSet.addItem( metadata.buildGQLField() );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'fullmakt',
            args,
            selectionSet
        );
    }
}
