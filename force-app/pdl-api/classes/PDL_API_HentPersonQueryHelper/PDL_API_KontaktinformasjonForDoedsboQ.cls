public with sharing class PDL_API_KontaktinformasjonForDoedsboQ {

    public Boolean historikk = false;

    public Boolean skifteform = false;
    public Boolean attestutstedelsesdato = false;
    PDL_API_KontaktinfoForDoedsboPersonQ personSomKontakt;
    PDL_API_KontaktinfoForDoedsboAdvokatQ advokatSomKontakt;
    PDL_API_KontaktinfoForDoedsboOrgQ organisasjonSomKontakt;
    PDL_API_KontaktinfoForDoedsboAdresseQ adresse;
    
    PDL_API_FolkeregistermetadataQuery folkeregistermetadata;
    PDL_API_MetadataQuery metadata;

    public PDL_API_KontaktinformasjonForDoedsboQ() {
        personSomKontakt = new PDL_API_KontaktinfoForDoedsboPersonQ();
        advokatSomKontakt = new PDL_API_KontaktinfoForDoedsboAdvokatQ();
        organisasjonSomKontakt = new PDL_API_KontaktinfoForDoedsboOrgQ();
        adresse = new PDL_API_KontaktinfoForDoedsboAdresseQ();
        folkeregistermetadata = new PDL_API_FolkeregistermetadataQuery();
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        skifteform = true;
        attestutstedelsesdato = true;
        personSomKontakt.selectAll();
        advokatSomKontakt.selectAll();
        organisasjonSomKontakt.selectAll();
        adresse.selectAll();
    }

    public void selectAll(Boolean includeMetadata){
        if(includeMetadata){
            folkeregistermetadata.selectAll();
            metadata.selectAll();
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   skifteform ||
                    attestutstedelsesdato ||
                    !personSomKontakt.isEmpty() ||
                    !advokatSomKontakt.isEmpty() ||
                    !organisasjonSomKontakt.isEmpty() ||
                    !adresse.isEmpty() ||
                    !folkeregistermetadata.isEmpty() || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( skifteform ) selectionSet.addItem( new GQLField( 'skifteform' ) );
        if ( attestutstedelsesdato ) selectionSet.addItem( new GQLField( 'attestutstedelsesdato' ) );
        selectionSet.addItem(personSomKontakt.buildGQLField());
        selectionSet.addItem(advokatSomKontakt.buildGQLField());
        selectionSet.addItem(organisasjonSomKontakt.buildGQLField());
        selectionSet.addItem(adresse.buildGQLField());
        selectionSet.addItem( folkeregistermetadata.buildGQLField() );
        selectionSet.addItem( metadata.buildGQLField() );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'kontaktinformasjonForDoedsbo',
            args,
            selectionSet
        );
    }
}
