public with sharing class PDL_API_StatsborgerskapQuery {

    public Boolean historikk = false;

    public Boolean land = false;
    public Boolean bekreftelsesdato = false;
    public Boolean gyldigFraOgMed = false;
    public Boolean gyldigTilOgMed = false;

    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_StatsborgerskapQuery() {

    }

    public Boolean isEmpty(){
        return !(   land ||
                    bekreftelsesdato ||
                    gyldigFraOgMed ||
                    gyldigTilOgMed ||
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( land ) selectionSet.addItem( new GQLField( 'land' ) );
        if ( bekreftelsesdato ) selectionSet.addItem( new GQLField( 'bekreftelsesdato' ) );
        if ( gyldigFraOgMed ) selectionSet.addItem( new GQLField( 'gyldigFraOgMed' ) );
        if ( gyldigTilOgMed ) selectionSet.addItem( new GQLField( 'gyldigTilOgMed' ) );
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

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
