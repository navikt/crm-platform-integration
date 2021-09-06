public with sharing class PDL_API_DeltBostedQuery {

    public Boolean historikk = false;

    public Boolean startdatoForKontrakt = false;
    public Boolean sluttdatoForKontrakt = false;
    public Boolean coAdressenavn = false;
    public PDL_API_VegadresseQuery vegadresse;
    public PDL_API_MatrikkeladresseQuery matrikkeladresse;
    public PDL_API_UtenlandskAdresseQuery utenlandskAdresse;
    public PDL_API_UkjentBostedQuery ukjentBosted;

    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_DeltBostedQuery() {
        vegadresse = new PDL_API_VegadresseQuery();
        matrikkeladresse = new PDL_API_MatrikkeladresseQuery();
        utenlandskAdresse = new PDL_API_UtenlandskAdresseQuery();
        ukjentBosted = new PDL_API_UkjentBostedQuery();
    }

    public Boolean isEmpty(){
        return !(   startdatoForKontrakt ||
                    sluttdatoForKontrakt ||
                    coAdressenavn ||
                    !vegadresse.isEmpty() ||
                    !matrikkeladresse.isEmpty() ||
                    !utenlandskAdresse.isEmpty() ||
                    !ukjentBosted.isEmpty() ||
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( startdatoForKontrakt ) selectionSet.addItem( new GQLField( 'startdatoForKontrakt' ) );
        if ( sluttdatoForKontrakt ) selectionSet.addItem( new GQLField( 'sluttdatoForKontrakt' ) );
        if ( coAdressenavn ) selectionSet.addItem( new GQLField( 'coAdressenavn' ) );
        if ( !vegadresse.isEmpty() ) selectionSet.addItem(vegadresse.buildGQLField());
        if ( !matrikkeladresse.isEmpty() ) selectionSet.addItem(matrikkeladresse.buildGQLField());
        if ( !utenlandskAdresse.isEmpty() ) selectionSet.addItem(utenlandskAdresse.buildGQLField());
        if ( !ukjentBosted.isEmpty() ) selectionSet.addItem(ukjentBosted.buildGQLField());
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'deltBosted',
            args,
            selectionSet
        );
    }
}
