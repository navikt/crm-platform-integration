public with sharing class PDL_API_Query {
    public static String Navn(String ident){
        PDL_API_HentPersonQuery query = new PDL_API_HentPersonQuery(ident);
        query.hentPerson.navn.fornavn = true;
        query.hentPerson.navn.mellomnavn = true;
        query.hentPerson.navn.etternavn = true;
        return query.build();
    }
    public static String Ansvarssubjekt(String ident){
        /*
        return '{"query": "query($ident: ID!){ hentPerson(ident: $ident)'
        +' {navn(historikk: false) {fornavn mellomnavn etternavn}}}",'
        +'"variables": {"ident":"' + ident + '"}}';
        */
        
        PDL_API_HentPersonQuery query = new PDL_API_HentPersonQuery(ident);
        query.hentPerson.foreldreansvar.ansvarssubjekt = true;

        return query.build();

        /* GQLVariable VarIdent = new GQLVariable('ident',new GQLVariableType('ID!'));
        Map<String,String> variables = new Map<String,String>{ VarIdent.getName() => ident};
        GQLQuery q = new GQLQuery(
            new GQLOperation(
                new GQLOperationType(GQLOperationType_e.QUERY),
                '', //noname
                new GQLVariableDefinitions().addVariable(VarIdent),
                new GQLSelectionSet().addItem(
                    new GQLField(
                        'hentPerson',
                        new GQLArguments().addArgument(
                            new GQLArgument(
                                'ident',
                                new GQLValue(VarIdent)
                            )
                        ),
                        new GQLSelectionSet().addItem(
                            new GQLField('foreldreansvar',
                                new GQLArguments().addArgument(
                                    new GQLArgument(
                                        'historikk',
                                        new GQLValue(false)
                                    )
                                ),
                                new GQLSelectionSet().addItem(
                                    new GQLField('ansvarssubjekt')
                                )
                            )
                        )
                    )
                )
            ),
            variables
        );

        String s = q.build();
        System.debug(s);
        return s; */
    }

    public static String allFields(String ident){
        PDL_API_HentPersonQuery query = new PDL_API_HentPersonQuery(ident);
        query.hentPerson.adressebeskyttelse.selectAll(true);
        query.hentPerson.bostedsadresse.selectAll(true);
        query.hentPerson.deltBosted.selectAll(true);
        query.hentPerson.doedfoedtBarn.selectAll(true);
        query.hentPerson.doedsfall.selectAll(true);
        query.hentPerson.falskIdentitet.selectAll(true);
        query.hentPerson.foedsel.selectAll(true);
        query.hentPerson.folkeregisteridentifikator.selectAll(true);
        query.hentPerson.folkeregisterpersonstatus.selectAll(true);
        query.hentPerson.forelderBarnRelasjon.selectAll(true);
        query.hentPerson.foreldreansvar.selectAll(true);
        query.hentPerson.fullmakt.selectAll(true);
        query.hentPerson.identitetsgrunnlag.selectAll(true);
        query.hentPerson.innflyttingTilNorge.selectAll(true);
        query.hentPerson.kjoenn.selectAll(true);
        query.hentPerson.kontaktadresse.selectAll(true);
        query.hentPerson.kontaktinformasjonForDoedsbo.selectAll(true);
        query.hentPerson.navn.selectAll(true);
        query.hentPerson.opphold.selectAll(true);
        query.hentPerson.oppholdsadresse.selectAll(true);
        query.hentPerson.sikkerhetstiltak.selectAll(true);
        query.hentPerson.sivilstand.selectAll(true);
        query.hentPerson.statsborgerskap.selectAll(true);
        query.hentPerson.telefonnummer.selectAll(true);
        query.hentPerson.tilrettelagtKommunikasjon.selectAll(true);
        query.hentPerson.utenlandskIdentifikasjonsnummer.selectAll(true);
        query.hentPerson.utflyttingFraNorge.selectAll(true);
        query.hentPerson.vergemaalEllerFremtidsfullmakt.selectAll(true);

        return query.build();
    }
}
