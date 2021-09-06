public with sharing class PDL_API_OppholdsadresseQuery {

    public Boolean historikk = false;

    public Boolean gyldigFraOgMed = false;
    public Boolean gyldigTilOgMed = false;
    public Boolean coAdressenavn = false;
    public PDL_API_UtenlandskAdresseQuery utenlandskAdresse;
    public PDL_API_VegadresseQuery vegadresse;
    public PDL_API_MatrikkeladresseQuery matrikkeladresse;
    public Boolean oppholdAnnetSted = false;

    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_OppholdsadresseQuery() {
        utenlandskAdresse = new PDL_API_UtenlandskAdresseQuery();
        vegadresse = new PDL_API_VegadresseQuery();
        matrikkeladresse = new PDL_API_MatrikkeladresseQuery();
    }

    public Boolean isEmpty(){
        return !(   gyldigFraOgMed ||
                    gyldigTilOgMed ||
                    coAdressenavn ||
                    !utenlandskAdresse.isEmpty() ||
                    !vegadresse.isEmpty() ||
                    !matrikkeladresse.isEmpty() ||
                    oppholdAnnetSted ||
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( gyldigFraOgMed ) selectionSet.addItem( new GQLField( 'gyldigFraOgMed' ) );
        if ( gyldigTilOgMed ) selectionSet.addItem( new GQLField( 'gyldigTilOgMed' ) );
        if ( coAdressenavn ) selectionSet.addItem( new GQLField( 'coAdressenavn' ) );
        if ( !utenlandskAdresse.isEmpty() ) selectionSet.addItem(utenlandskAdresse.buildGQLField());
        if ( !vegadresse.isEmpty() ) selectionSet.addItem(vegadresse.buildGQLField());
        if ( !matrikkeladresse.isEmpty() ) selectionSet.addItem(matrikkeladresse.buildGQLField());
        if ( oppholdAnnetSted ) selectionSet.addItem( new GQLField( 'oppholdAnnetSted' ) );
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'oppholdsadresse',
            args,
            selectionSet
        );
    }
}
