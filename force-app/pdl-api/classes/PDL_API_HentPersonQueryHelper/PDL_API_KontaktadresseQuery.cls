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

    PDL_API_FolkeregistermetadataQuery folkeregistermetadata;
    PDL_API_MetadataQuery metadata;

    public PDL_API_KontaktadresseQuery() {
        postboksadresse = new PDL_API_PostboksadresseQuery();
        vegadresse = new PDL_API_VegadresseQuery();
        postadresseIFrittFormat = new PDL_API_PostadresseIFrittFormatQuery();
        utenlandskAdresse = new PDL_API_UtenlandskAdresseQuery();
        utenlandskAdresseIFrittFormat = new PDL_API_UtenlandskAdresseIFrittFormatQ();
        folkeregistermetadata = new PDL_API_FolkeregistermetadataQuery();
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        gyldigFraOgMed = true;
        gyldigTilOgMed = true;
        type = true;
        coAdressenavn = true;
        postboksadresse.selectAll();
        vegadresse.selectAll();
        postadresseIFrittFormat.selectAll();
        utenlandskAdresse.selectAll();
        utenlandskAdresseIFrittFormat.selectAll();
    }
    public void selectAll(Boolean includeMetadata){
        if(includeMetadata){
            folkeregistermetadata.selectAll();
            metadata.selectAll();
        }
        selectAll();
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
                    !folkeregistermetadata.isEmpty() || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( gyldigFraOgMed ) selectionSet.addItem( new GQLField( 'gyldigFraOgMed' ) );
        if ( gyldigTilOgMed ) selectionSet.addItem( new GQLField( 'gyldigTilOgMed' ) );
        if ( type ) selectionSet.addItem( new GQLField( 'type' ) );
        if ( coAdressenavn ) selectionSet.addItem( new GQLField( 'coAdressenavn' ) );
        selectionSet.addItem(postboksadresse.buildGQLField());
        selectionSet.addItem(vegadresse.buildGQLField());
        selectionSet.addItem(postadresseIFrittFormat.buildGQLField());
        selectionSet.addItem(utenlandskAdresse.buildGQLField());
        selectionSet.addItem(utenlandskAdresseIFrittFormat.buildGQLField());
        selectionSet.addItem( folkeregistermetadata.buildGQLField() );
        selectionSet.addItem( metadata.buildGQLField() );

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
