public with sharing class PDL_API_FullmaktQuery {

    public Boolean historikk = false;

    public Boolean motpartsPersonident = false;
    public Boolean motpartsRolle = false;
    public Boolean omraader = false;
    public Boolean gyldigFraOgMed = false;
    public Boolean gyldigTilOgMed = false;

    public Boolean metadata = false;

    public PDL_API_FullmaktQuery() {

    }

    public Boolean isEmpty(){
        return !(   motpartsPersonident ||
                    motpartsRolle ||
                    omraader ||
                    gyldigFraOgMed ||
                    gyldigTilOgMed || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( motpartsPersonident ) selectionSet.addItem( new GQLField( 'motpartsPersonident' ) );
        if ( motpartsRolle ) selectionSet.addItem( new GQLField( 'motpartsRolle' ) );
        if ( omraader ) selectionSet.addItem( new GQLField( 'omraader' ) );
        if ( gyldigFraOgMed ) selectionSet.addItem( new GQLField( 'gyldigFraOgMed' ) );
        if ( gyldigTilOgMed ) selectionSet.addItem( new GQLField( 'gyldigTilOgMed' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

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
