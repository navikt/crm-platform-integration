public with sharing class PDL_API_KontaktinformasjonForDoedsboQ {

    public Boolean historikk = false;

    public Boolean skifteform = false;
    public Boolean attestutstedelsesdato = false;
    PDL_API_KontaktinfoForDoedsboPersonQ personSomKontakt;
    PDL_API_KontaktinfoForDoedsboAdvokatQ advokatSomKontakt;
    PDL_API_KontaktinfoForDoedsboOrgQ organisasjonSomKontakt;
    PDL_API_KontaktinfoForDoedsboAdresseQ adresse;
    
    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_KontaktinformasjonForDoedsboQ() {
        personSomKontakt = new PDL_API_KontaktinfoForDoedsboPersonQ();
        advokatSomKontakt = new PDL_API_KontaktinfoForDoedsboAdvokatQ();
        organisasjonSomKontakt = new PDL_API_KontaktinfoForDoedsboOrgQ();
        adresse = new PDL_API_KontaktinfoForDoedsboAdresseQ();
    }

    public Boolean isEmpty(){
        return !(   skifteform ||
                    attestutstedelsesdato ||
                    !personSomKontakt.isEmpty() ||
                    !advokatSomKontakt.isEmpty() ||
                    !organisasjonSomKontakt.isEmpty() ||
                    !adresse.isEmpty() ||
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( skifteform ) selectionSet.addItem( new GQLField( 'skifteform' ) );
        if ( attestutstedelsesdato ) selectionSet.addItem( new GQLField( 'attestutstedelsesdato' ) );
        if ( !personSomKontakt.isEmpty() ) selectionSet.addItem(personSomKontakt.buildGQLField());
        if ( !advokatSomKontakt.isEmpty() ) selectionSet.addItem(advokatSomKontakt.buildGQLField());
        if ( !organisasjonSomKontakt.isEmpty() ) selectionSet.addItem(organisasjonSomKontakt.buildGQLField());
        if ( !adresse.isEmpty() ) selectionSet.addItem(adresse.buildGQLField());
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

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
