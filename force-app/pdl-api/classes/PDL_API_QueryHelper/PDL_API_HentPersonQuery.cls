public with sharing class PDL_API_HentPersonQuery {
    GQLVariable ident;

    public PDL_API_AdressebeskyttelseQuery adressebeskyttelse;
    public PDL_API_BostedsadresseQuery bostedsadresse;
    public PDL_API_DeltBostedQuery deltBosted;
    public PDL_API_DoedfoedtBarnQuery doedfoedtBarn;
    public PDL_API_DoedsfallQuery doedsfall;
    public PDL_API_FalskIdentitetQuery falskIdentitet;
    public PDL_API_FoedestedQuery foedested;
    public PDL_API_FoedselsdatoQuery foedselsdato;
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

    public PDL_API_HentPersonQuery(GQLVariable ident) {
        this.ident = ident;

        adressebeskyttelse = new PDL_API_AdressebeskyttelseQuery();
        bostedsadresse = new PDL_API_BostedsadresseQuery();
        deltBosted = new PDL_API_DeltBostedQuery();
        doedfoedtBarn = new PDL_API_DoedfoedtBarnQuery();
        doedsfall = new PDL_API_DoedsfallQuery();
        falskIdentitet = new PDL_API_FalskIdentitetQuery();
        foedested = new PDL_API_FoedestedQuery();
        foedselsdato = new PDL_API_FoedselsdatoQuery();
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

    public void selectAll() {
        adressebeskyttelse.selectAll();
        bostedsadresse.selectAll();
        deltBosted.selectAll();
        doedfoedtBarn.selectAll();
        doedsfall.selectAll();
        falskIdentitet.selectAll();
        foedested.selectAll();
        foedselsdato.selectAll();
        folkeregisteridentifikator.selectAll();
        folkeregisterpersonstatus.selectAll();
        forelderBarnRelasjon.selectAll();
        foreldreansvar.selectAll();
        fullmakt.selectAll();
        identitetsgrunnlag.selectAll();
        innflyttingTilNorge.selectAll();
        kjoenn.selectAll();
        kontaktadresse.selectAll();
        kontaktinformasjonForDoedsbo.selectAll();
        navn.selectAll();
        opphold.selectAll();
        oppholdsadresse.selectAll();
        sikkerhetstiltak.selectAll();
        sivilstand.selectAll();
        statsborgerskap.selectAll();
        telefonnummer.selectAll();
        tilrettelagtKommunikasjon.selectAll();
        utenlandskIdentifikasjonsnummer.selectAll();
        utflyttingFraNorge.selectAll();
        vergemaalEllerFremtidsfullmakt.selectAll();
    }

    public void selectAll(Boolean includeMetadata) {
        adressebeskyttelse.selectAll(includeMetadata);
        bostedsadresse.selectAll(includeMetadata);
        deltBosted.selectAll(includeMetadata);
        doedfoedtBarn.selectAll(includeMetadata);
        doedsfall.selectAll(includeMetadata);
        falskIdentitet.selectAll(includeMetadata);
        foedested.selectAll(includeMetadata);
        foedselsdato.selectAll(includeMetadata);
        folkeregisteridentifikator.selectAll(includeMetadata);
        folkeregisterpersonstatus.selectAll(includeMetadata);
        forelderBarnRelasjon.selectAll(includeMetadata);
        foreldreansvar.selectAll(includeMetadata);
        fullmakt.selectAll(includeMetadata);
        identitetsgrunnlag.selectAll(includeMetadata);
        innflyttingTilNorge.selectAll(includeMetadata);
        kjoenn.selectAll(includeMetadata);
        kontaktadresse.selectAll(includeMetadata);
        kontaktinformasjonForDoedsbo.selectAll(includeMetadata);
        navn.selectAll(includeMetadata);
        opphold.selectAll(includeMetadata);
        oppholdsadresse.selectAll(includeMetadata);
        sikkerhetstiltak.selectAll(includeMetadata);
        sivilstand.selectAll(includeMetadata);
        statsborgerskap.selectAll(includeMetadata);
        telefonnummer.selectAll(includeMetadata);
        tilrettelagtKommunikasjon.selectAll(includeMetadata);
        utenlandskIdentifikasjonsnummer.selectAll(includeMetadata);
        utflyttingFraNorge.selectAll(includeMetadata);
        vergemaalEllerFremtidsfullmakt.selectAll(includeMetadata);
    }

    public Boolean isEmpty() {
        return (adressebeskyttelse.isEmpty() &&
        bostedsadresse.isEmpty() &&
        deltBosted.isEmpty() &&
        doedfoedtBarn.isEmpty() &&
        doedsfall.isEmpty() &&
        falskIdentitet.isEmpty() &&
        foedested.isEmpty() &&
        foedselsdato.isEmpty() &&
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
        vergemaalEllerFremtidsfullmakt.isEmpty());
    }

    public GQLField buildGQLField() {
        if (isEmpty() || ident == null)
            return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        selectionSet.addItem(adressebeskyttelse.buildGQLField());
        selectionSet.addItem(bostedsadresse.buildGQLField());
        selectionSet.addItem(deltBosted.buildGQLField());
        selectionSet.addItem(doedfoedtBarn.buildGQLField());
        selectionSet.addItem(doedsfall.buildGQLField());
        selectionSet.addItem(falskIdentitet.buildGQLField());
        selectionSet.addItem(foedested.buildGQLField());
        selectionSet.addItem(foedselsdato.buildGQLField());
        selectionSet.addItem(folkeregisteridentifikator.buildGQLField());
        selectionSet.addItem(folkeregisterpersonstatus.buildGQLField());
        selectionSet.addItem(forelderBarnRelasjon.buildGQLField());
        selectionSet.addItem(foreldreansvar.buildGQLField());
        selectionSet.addItem(fullmakt.buildGQLField());
        selectionSet.addItem(identitetsgrunnlag.buildGQLField());
        selectionSet.addItem(kjoenn.buildGQLField());
        selectionSet.addItem(kontaktadresse.buildGQLField());
        selectionSet.addItem(kontaktinformasjonForDoedsbo.buildGQLField());
        selectionSet.addItem(navn.buildGQLField());
        selectionSet.addItem(opphold.buildGQLField());
        selectionSet.addItem(oppholdsadresse.buildGQLField());
        selectionSet.addItem(sikkerhetstiltak.buildGQLField());
        selectionSet.addItem(sivilstand.buildGQLField());
        selectionSet.addItem(statsborgerskap.buildGQLField());
        selectionSet.addItem(telefonnummer.buildGQLField());
        selectionSet.addItem(tilrettelagtKommunikasjon.buildGQLField());
        selectionSet.addItem(utenlandskIdentifikasjonsnummer.buildGQLField());
        selectionSet.addItem(innflyttingTilNorge.buildGQLField());
        selectionSet.addItem(utflyttingFraNorge.buildGQLField());
        selectionSet.addItem(vergemaalEllerFremtidsfullmakt.buildGQLField());

        GQLArguments args = new GQLArguments().addArgument(new GQLArgument('ident', new GQLValue(ident)));

        return new GQLField('hentPerson', args, selectionSet);
    }
}
