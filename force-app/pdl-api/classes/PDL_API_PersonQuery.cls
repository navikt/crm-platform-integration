public with sharing class PDL_API_PersonQuery {
    GQLVariable ident;

    public PDL_API_AdressebeskyttelseQuery adressebeskyttelse;
    public PDL_API_BostedsadresseQuery bostedsadresse;
    // public PDL_API_DeltBostedQuery deltBosted;
    // public PDL_API_DoedfoedtBarnQuery doedfoedtBarn;
    // public PDL_API_DoedsfallQuery doedsfall;
    // public PDL_API_FalskIdentitetQuery falskIdentitet;
    // public PDL_API_FoedselQuery foedsel;
    // public PDL_API_FolkeregisteridentifikatorQuery folkeregisteridentifikator;
    // public PDL_API_FolkeregisterpersonstatusQuery folkeregisterpersonstatus;
    // public PDL_API_ForelderBarnRelasjonQuery forelderBarnRelasjon;
    public PDL_API_ForeldreansvarQuery foreldreansvar;
    // public PDL_API_FullmaktQuery fullmakt;
    // public PDL_API_IdentitetsgrunnlagQuery identitetsgrunnlag;
    // public PDL_API_KjoennQuery kjoenn;
    // public PDL_API_KontaktadresseQuery kontaktadresse;
    // public PDL_API_KontaktinformasjonForDoedsboQuery kontaktinformasjonForDoedsbo;
    public PDL_API_NavnQuery navn;
    // public PDL_API_OppholdQuery opphold;
    // public PDL_API_OppholdsadresseQuery oppholdsadresse;
    // public PDL_API_SikkerhetstiltakQuery sikkerhetstiltak;
    // public PDL_API_SivilstandQuery sivilstand;
    // public PDL_API_StatsborgerskapQuery statsborgerskap;
    // public PDL_API_TelefonnummerQuery telefonnummer;
    // public PDL_API_TilrettelagtKommunikasjonQuery tilrettelagtKommunikasjon;
    // public PDL_API_UtenlandskIdentifikasjonsnummerQuery utenlandskIdentifikasjonsnummer;
    // public PDL_API_InnflyttingTilNorgeQuery innflyttingTilNorge;
    // public PDL_API_UtflyttingFraNorgeQuery utflyttingFraNorge;
    // public PDL_API_VergemaalEllerFremtidsfullmaktQuery vergemaalEllerFremtidsfullmakt;

    public PDL_API_PersonQuery(GQLVariable ident) {
        this.ident = ident;
        navn = new PDL_API_NavnQuery();
        foreldreansvar = new PDL_API_ForeldreansvarQuery();
    }

    public Boolean isEmpty(){
        return ( navn.isEmpty() && foreldreansvar.isEmpty() ) ;
    }

    public GQLField buildGQLField(){
        if(isEmpty() || ident == null) return null;
        
        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( !navn.isEmpty() ) selectionSet.addItem( navn.buildGQLField() );
        if ( !foreldreansvar.isEmpty() ) selectionSet.addItem( foreldreansvar.buildGQLField() );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'ident', new GQLValue(ident)
            )
        );

        return new GQLField(
            'hentPerson',
            args,
            selectionSet
        );
    }

}
