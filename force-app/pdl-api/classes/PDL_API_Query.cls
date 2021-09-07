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
        query.hentPerson.adressebeskyttelse.selectAll();
        query.hentPerson.bostedsadresse.selectAll();
        query.hentPerson.deltBosted.selectAll();
        query.hentPerson.doedfoedtBarn.selectAll();
        query.hentPerson.doedsfall.selectAll();
        query.hentPerson.falskIdentitet.selectAll();
        query.hentPerson.foedsel.selectAll();
        query.hentPerson.folkeregisteridentifikator.selectAll();
        query.hentPerson.folkeregisterpersonstatus.selectAll();
        query.hentPerson.forelderBarnRelasjon.selectAll();
        query.hentPerson.foreldreansvar.selectAll();
        query.hentPerson.fullmakt.selectAll();
        query.hentPerson.identitetsgrunnlag.selectAll();
        query.hentPerson.innflyttingTilNorge.selectAll();
        query.hentPerson.kjoenn.selectAll();
        query.hentPerson.kontaktadresse.selectAll();
        query.hentPerson.kontaktinformasjonForDoedsbo.selectAll();
        query.hentPerson.navn.selectAll();
        query.hentPerson.opphold.selectAll();
        query.hentPerson.oppholdsadresse.selectAll();
        query.hentPerson.sikkerhetstiltak.selectAll();
        query.hentPerson.sivilstand.selectAll();
        query.hentPerson.statsborgerskap.selectAll();
        query.hentPerson.telefonnummer.selectAll();
        query.hentPerson.tilrettelagtKommunikasjon.selectAll();
        query.hentPerson.utenlandskIdentifikasjonsnummer.selectAll();
        query.hentPerson.utflyttingFraNorge.selectAll();
        query.hentPerson.vergemaalEllerFremtidsfullmakt.selectAll();

        return query.build();
    }
}
