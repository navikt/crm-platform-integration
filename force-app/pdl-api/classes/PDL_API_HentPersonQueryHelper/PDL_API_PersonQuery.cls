public with sharing class PDL_API_PersonQuery {
    GQLVariable ident;

    public PDL_API_AdressebeskyttelseQuery adressebeskyttelse;
    public PDL_API_BostedsadresseQuery bostedsadresse;
    public PDL_API_DeltBostedQuery deltBosted;
    public PDL_API_DoedfoedtBarnQuery doedfoedtBarn;
    public PDL_API_DoedsfallQuery doedsfall;
    public PDL_API_FalskIdentitetQuery falskIdentitet;
    public PDL_API_FoedselQuery foedsel;
    public PDL_API_FolkeregisteridentifikatorQuery folkeregisteridentifikator;
    public PDL_API_FolkeregisterpersonstatusQuery folkeregisterpersonstatus;
    public PDL_API_ForelderBarnRelasjonQuery forelderBarnRelasjon;
    public PDL_API_ForeldreansvarQuery foreldreansvar;
    public PDL_API_FullmaktQuery fullmakt;
    public PDL_API_IdentitetsgrunnlagQuery identitetsgrunnlag;
    public PDL_API_KjoennQuery kjoenn;
    public PDL_API_KontaktadresseQuery kontaktadresse;
    public PDL_API_KontaktinformasjonForDoedsboQ kontaktinformasjonForDoedsbo;
    public PDL_API_NavnQuery navn;
    public PDL_API_OppholdQuery opphold;
    public PDL_API_OppholdsadresseQuery oppholdsadresse;
    public PDL_API_SikkerhetstiltakQuery sikkerhetstiltak;
    public PDL_API_SivilstandQuery sivilstand;
    public PDL_API_StatsborgerskapQuery statsborgerskap;
    public PDL_API_TelefonnummerQuery telefonnummer;
    public PDL_API_TilrettelagtKommunikasjonQuery tilrettelagtKommunikasjon;
    public PDL_API_UtenlandskIdentifikasjonsnummerQ utenlandskIdentifikasjonsnummer;
    public PDL_API_InnflyttingTilNorgeQuery innflyttingTilNorge;
    public PDL_API_UtflyttingFraNorgeQuery utflyttingFraNorge;
    public PDL_API_VergemaalEllerFremtidsfullmaktQ vergemaalEllerFremtidsfullmakt;

    public PDL_API_PersonQuery(GQLVariable ident) {
        this.ident = ident;

        adressebeskyttelse = new PDL_API_AdressebeskyttelseQuery();
        bostedsadresse = new PDL_API_BostedsadresseQuery();
        deltBosted = new PDL_API_DeltBostedQuery();
        doedfoedtBarn = new PDL_API_DoedfoedtBarnQuery();
        doedsfall = new PDL_API_DoedsfallQuery();
        falskIdentitet = new PDL_API_FalskIdentitetQuery();
        foedsel = new PDL_API_FoedselQuery();
        folkeregisteridentifikator = new PDL_API_FolkeregisteridentifikatorQuery();
        folkeregisterpersonstatus = new PDL_API_FolkeregisterpersonstatusQuery();
        forelderBarnRelasjon = new PDL_API_ForelderBarnRelasjonQuery();
        foreldreansvar = new PDL_API_ForeldreansvarQuery();
        fullmakt = new PDL_API_FullmaktQuery();
        identitetsgrunnlag = new PDL_API_IdentitetsgrunnlagQuery();
        kjoenn = new PDL_API_KjoennQuery();
        kontaktadresse = new PDL_API_KontaktadresseQuery();
        kontaktinformasjonForDoedsbo = new PDL_API_KontaktinformasjonForDoedsboQ();
        navn = new PDL_API_NavnQuery();
        opphold = new PDL_API_OppholdQuery();
        oppholdsadresse = new PDL_API_OppholdsadresseQuery();
        sikkerhetstiltak = new PDL_API_SikkerhetstiltakQuery();
        sivilstand = new PDL_API_SivilstandQuery();
        statsborgerskap = new PDL_API_StatsborgerskapQuery();
        telefonnummer = new PDL_API_TelefonnummerQuery();
        tilrettelagtKommunikasjon = new PDL_API_TilrettelagtKommunikasjonQuery();
        utenlandskIdentifikasjonsnummer = new PDL_API_UtenlandskIdentifikasjonsnummerQ();
        innflyttingTilNorge = new PDL_API_InnflyttingTilNorgeQuery();
        utflyttingFraNorge = new PDL_API_UtflyttingFraNorgeQuery();
        vergemaalEllerFremtidsfullmakt = new PDL_API_VergemaalEllerFremtidsfullmaktQ();
    }

    public Boolean isEmpty(){
        return (    adressebeskyttelse.isEmpty() && 
        bostedsadresse.isEmpty() &&
        deltBosted.isEmpty() &&
        doedfoedtBarn.isEmpty() &&
        doedsfall.isEmpty() &&
        falskIdentitet.isEmpty() &&
        foedsel.isEmpty() &&
        folkeregisteridentifikator.isEmpty() &&
        folkeregisterpersonstatus.isEmpty() &&
        forelderBarnRelasjon.isEmpty() &&
        foreldreansvar.isEmpty() &&
        fullmakt.isEmpty() &&
        identitetsgrunnlag.isEmpty() &&
        kjoenn.isEmpty() &&
        kontaktadresse.isEmpty() &&
        kontaktinformasjonForDoedsbo.isEmpty() &&
        navn.isEmpty() &&
        opphold.isEmpty() &&
        oppholdsadresse.isEmpty() &&
        sikkerhetstiltak.isEmpty() &&
        sivilstand.isEmpty() &&
        statsborgerskap.isEmpty() &&
        telefonnummer.isEmpty() &&
        tilrettelagtKommunikasjon.isEmpty() &&
        utenlandskIdentifikasjonsnummer.isEmpty() &&
        innflyttingTilNorge.isEmpty() &&
        utflyttingFraNorge.isEmpty() &&
        vergemaalEllerFremtidsfullmakt.isEmpty() ) ;
    }

    public GQLField buildGQLField(){
        if(isEmpty() || ident == null) return null;
        
        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( !adressebeskyttelse.isEmpty() ) selectionSet.addItem( adressebeskyttelse.buildGQLField() );
        if ( !bostedsadresse.isEmpty() ) selectionSet.addItem( bostedsadresse.buildGQLField() );
        if ( !deltBosted.isEmpty() ) selectionSet.addItem( deltBosted.buildGQLField() );
        if ( !doedfoedtBarn.isEmpty() ) selectionSet.addItem( doedfoedtBarn.buildGQLField() );
        if ( !doedsfall.isEmpty() ) selectionSet.addItem( doedsfall.buildGQLField() );
        if ( !falskIdentitet.isEmpty() ) selectionSet.addItem( falskIdentitet.buildGQLField() );
        if ( !foedsel.isEmpty() ) selectionSet.addItem( foedsel.buildGQLField() );
        if ( !folkeregisteridentifikator.isEmpty() ) selectionSet.addItem( folkeregisteridentifikator.buildGQLField() );
        if ( !folkeregisterpersonstatus.isEmpty() ) selectionSet.addItem( folkeregisterpersonstatus.buildGQLField() );
        if ( !forelderBarnRelasjon.isEmpty() ) selectionSet.addItem( forelderBarnRelasjon.buildGQLField() );
        if ( !foreldreansvar.isEmpty() ) selectionSet.addItem( foreldreansvar.buildGQLField() );
        if ( !fullmakt.isEmpty() ) selectionSet.addItem( fullmakt.buildGQLField() );
        if ( !identitetsgrunnlag.isEmpty() ) selectionSet.addItem( identitetsgrunnlag.buildGQLField() );
        if ( !kjoenn.isEmpty() ) selectionSet.addItem( kjoenn.buildGQLField() );
        if ( !kontaktadresse.isEmpty() ) selectionSet.addItem( kontaktadresse.buildGQLField() );
        if ( !kontaktinformasjonForDoedsbo.isEmpty() ) selectionSet.addItem( kontaktinformasjonForDoedsbo.buildGQLField() );
        if ( !navn.isEmpty() ) selectionSet.addItem( navn.buildGQLField() );
        if ( !opphold.isEmpty() ) selectionSet.addItem( opphold.buildGQLField() );
        if ( !oppholdsadresse.isEmpty() ) selectionSet.addItem( oppholdsadresse.buildGQLField() );
        if ( !sikkerhetstiltak.isEmpty() ) selectionSet.addItem( sikkerhetstiltak.buildGQLField() );
        if ( !sivilstand.isEmpty() ) selectionSet.addItem( sivilstand.buildGQLField() );
        if ( !statsborgerskap.isEmpty() ) selectionSet.addItem( statsborgerskap.buildGQLField() );
        if ( !telefonnummer.isEmpty() ) selectionSet.addItem( telefonnummer.buildGQLField() );
        if ( !tilrettelagtKommunikasjon.isEmpty() ) selectionSet.addItem( tilrettelagtKommunikasjon.buildGQLField() );
        if ( !utenlandskIdentifikasjonsnummer.isEmpty() ) selectionSet.addItem( utenlandskIdentifikasjonsnummer.buildGQLField() );
        if ( !innflyttingTilNorge.isEmpty() ) selectionSet.addItem( innflyttingTilNorge.buildGQLField() );
        if ( !utflyttingFraNorge.isEmpty() ) selectionSet.addItem( utflyttingFraNorge.buildGQLField() );
        if ( !vergemaalEllerFremtidsfullmakt.isEmpty() ) selectionSet.addItem( vergemaalEllerFremtidsfullmakt.buildGQLField() );

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
