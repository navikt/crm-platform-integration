public with sharing class PDL_API_OppholdsadresseQuery {

    public Boolean historikk = false;

    public Boolean gyldigFraOgMed = false;
    public Boolean gyldigTilOgMed = false;
    public Boolean coAdressenavn = false;
    public PDL_API_UtenlandskAdresseQuery utenlandskAdresse;
    public PDL_API_VegadresseQuery vegadresse;
    public PDL_API_MatrikkeladresseQuery matrikkeladresse;
    public Boolean oppholdAnnetSted = false;

    PDL_API_FolkeregistermetadataQuery folkeregistermetadata;
    PDL_API_MetadataQuery metadata;

    public PDL_API_OppholdsadresseQuery() {
        utenlandskAdresse = new PDL_API_UtenlandskAdresseQuery();
        vegadresse = new PDL_API_VegadresseQuery();
        matrikkeladresse = new PDL_API_MatrikkeladresseQuery();
        folkeregistermetadata = new PDL_API_FolkeregistermetadataQuery();
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        gyldigFraOgMed = true;
        gyldigTilOgMed = true;
        coAdressenavn = true;
        utenlandskAdresse.selectAll();
        vegadresse.selectAll();
        matrikkeladresse.selectAll();
        oppholdAnnetSted = true;
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
                    coAdressenavn ||
                    !utenlandskAdresse.isEmpty() ||
                    !vegadresse.isEmpty() ||
                    !matrikkeladresse.isEmpty() ||
                    oppholdAnnetSted ||
                    !folkeregistermetadata.isEmpty() || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( gyldigFraOgMed ) selectionSet.addItem( new GQLField( 'gyldigFraOgMed' ) );
        if ( gyldigTilOgMed ) selectionSet.addItem( new GQLField( 'gyldigTilOgMed' ) );
        if ( coAdressenavn ) selectionSet.addItem( new GQLField( 'coAdressenavn' ) );
        selectionSet.addItem(utenlandskAdresse.buildGQLField());
        selectionSet.addItem(vegadresse.buildGQLField());
        selectionSet.addItem(matrikkeladresse.buildGQLField());
        if ( oppholdAnnetSted ) selectionSet.addItem( new GQLField( 'oppholdAnnetSted' ) );
        selectionSet.addItem( folkeregistermetadata.buildGQLField() );
        selectionSet.addItem( metadata.buildGQLField() );

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
