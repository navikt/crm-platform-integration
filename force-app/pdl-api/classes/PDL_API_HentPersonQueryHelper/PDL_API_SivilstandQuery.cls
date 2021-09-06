public with sharing class PDL_API_SivilstandQuery {

    public Boolean historikk = false;

    public Boolean type = false;
    public Boolean gyldigFraOgMed = false;
    public Boolean relatertVedSivilstand = false;
    public Boolean bekreftelsesdato = false;

    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_SivilstandQuery() {

    }

    public Boolean isEmpty(){
        return !(   type ||
                    gyldigFraOgMed ||
                    relatertVedSivilstand ||
                    bekreftelsesdato ||
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( type ) selectionSet.addItem( new GQLField( 'type' ) );
        if ( gyldigFraOgMed ) selectionSet.addItem( new GQLField( 'gyldigFraOgMed' ) );
        if ( relatertVedSivilstand ) selectionSet.addItem( new GQLField( 'relatertVedSivilstand' ) );
        if ( bekreftelsesdato ) selectionSet.addItem( new GQLField( 'bekreftelsesdato' ) );
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

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
