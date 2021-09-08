public with sharing class PDL_API_BostedsadresseQuery {
    public Boolean historikk = false;

    public Boolean angittFlyttedato = false;
    public Boolean gyldigFraOgMed = false;
    public Boolean gyldigTilOgMed = false;
    public Boolean coAdressenavn = false;
    public PDL_API_VegadresseQuery vegadresse;
    public PDL_API_MatrikkeladresseQuery matrikkeladresse;
    public PDL_API_UtenlandskAdresseQuery utenlandskAdresse;
    public PDL_API_UkjentBostedQuery ukjentBosted;


    PDL_API_FolkeregistermetadataQuery folkeregistermetadata;
    PDL_API_MetadataQuery metadata;

    public PDL_API_BostedsadresseQuery() {
        vegadresse = new PDL_API_VegadresseQuery();
        matrikkeladresse = new PDL_API_MatrikkeladresseQuery();
        utenlandskAdresse = new PDL_API_UtenlandskAdresseQuery();
        ukjentBosted = new PDL_API_UkjentBostedQuery();
        folkeregistermetadata = new PDL_API_FolkeregistermetadataQuery();
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        angittFlyttedato = true;
        gyldigFraOgMed = true;
        gyldigTilOgMed = true;
        coAdressenavn = true;
        vegadresse.selectAll();
        matrikkeladresse.selectAll();
        utenlandskAdresse.selectAll();
        ukjentBosted.selectAll();
    }
    public void selectAll(Boolean includeMetadata){
        if(includeMetadata){
            folkeregistermetadata.selectAll();
            metadata.selectAll();
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   angittFlyttedato ||
                    gyldigFraOgMed ||
                    gyldigTilOgMed ||
                    coAdressenavn ||
                    !vegadresse.isEmpty() ||
                    !matrikkeladresse.isEmpty() ||
                    !utenlandskAdresse.isEmpty() ||
                    !ukjentBosted.isEmpty() ||
                    !folkeregistermetadata.isEmpty() || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( angittFlyttedato ) selectionSet.addItem( new GQLField( 'angittFlyttedato' ) );
        if ( gyldigFraOgMed ) selectionSet.addItem( new GQLField( 'gyldigFraOgMed' ) );
        if ( gyldigTilOgMed ) selectionSet.addItem( new GQLField( 'gyldigTilOgMed' ) );
        if ( coAdressenavn ) selectionSet.addItem( new GQLField( 'coAdressenavn' ) );
        selectionSet.addItem(vegadresse.buildGQLField());
        selectionSet.addItem(matrikkeladresse.buildGQLField());
        selectionSet.addItem(utenlandskAdresse.buildGQLField());
        selectionSet.addItem(ukjentBosted.buildGQLField());
        selectionSet.addItem( folkeregistermetadata.buildGQLField() );
        selectionSet.addItem( metadata.buildGQLField() );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'bostedsadresse',
            args,
            selectionSet
        );
    }
}
