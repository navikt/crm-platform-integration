public with sharing class PDL_API_KontaktadresseQuery {

    public Boolean historikk = false;

    public Boolean gyldigFraOgMed = false;
    public Boolean gyldigTilOgMed = false;
    public Boolean type = false;
    public Boolean coAdressenavn = false;
    public PDL_API_PostboksadresseQuery postboksadresse;
    public PDL_API_VegadresseQuery vegadresse;
    public PDL_API_PostadresseIFrittFormatQuery postadresseIFrittFormat;
    public PDL_API_UtenlandskAdresseQuery utenlandskAdresse;
    public PDL_API_UtenlandskAdresseIFrittFormatQ utenlandskAdresseIFrittFormat;


    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_KontaktadresseQuery() {
        postboksadresse = new PDL_API_PostboksadresseQuery();
        vegadresse = new PDL_API_VegadresseQuery();
        postadresseIFrittFormat = new PDL_API_PostadresseIFrittFormatQuery();
        utenlandskAdresse = new PDL_API_UtenlandskAdresseQuery();
        utenlandskAdresseIFrittFormat = new PDL_API_UtenlandskAdresseIFrittFormatQ();
    }

    public Boolean isEmpty(){
        return !(   gyldigFraOgMed ||
                    gyldigTilOgMed ||
                    type ||
                    coAdressenavn ||
                    !postboksadresse.isEmpty() ||
                    !vegadresse.isEmpty() ||
                    !postadresseIFrittFormat.isEmpty() ||
                    !utenlandskAdresse.isEmpty() ||
                    !utenlandskAdresseIFrittFormat.isEmpty() ||
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( gyldigFraOgMed ) selectionSet.addItem( new GQLField( 'gyldigFraOgMed' ) );
        if ( gyldigTilOgMed ) selectionSet.addItem( new GQLField( 'gyldigTilOgMed' ) );
        if ( type ) selectionSet.addItem( new GQLField( 'type' ) );
        if ( coAdressenavn ) selectionSet.addItem( new GQLField( 'coAdressenavn' ) );
        if ( !postboksadresse.isEmpty() ) selectionSet.addItem(postboksadresse.buildGQLField());
        if ( !vegadresse.isEmpty() ) selectionSet.addItem(vegadresse.buildGQLField());
        if ( !postadresseIFrittFormat.isEmpty() ) selectionSet.addItem(postadresseIFrittFormat.buildGQLField());
        if ( !utenlandskAdresse.isEmpty() ) selectionSet.addItem(utenlandskAdresse.buildGQLField());
        if ( !utenlandskAdresseIFrittFormat.isEmpty() ) selectionSet.addItem(utenlandskAdresseIFrittFormat.buildGQLField());
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'kontaktadresse',
            args,
            selectionSet
        );
    }
}
