public with sharing class PDL_API_Query {
    public static String Navn(String ident){
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
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
        
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
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
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.selectAll(true);
        query.hentIdenter.selectAll();
        query.addIdentGruppe(PDL_API_IdentGruppeQuery.AKTORID);
        query.addIdentGruppe(PDL_API_IdentGruppeQuery.FOLKEREGISTERIDENT);
        query.addIdentGruppe(PDL_API_IdentGruppeQuery.NPID);

        return query.build();
    }
}
