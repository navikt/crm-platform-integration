public with sharing class PDL_API_Query {
    public static String Ansvarssubjekt(String ident){
        /*
        return '{"query": "query($ident: ID!){ hentPerson(ident: $ident)'
        +' {navn(historikk: false) {fornavn mellomnavn etternavn}}}",'
        +'"variables": {"ident":"' + ident + '"}}';
        */
        
        GQLVariable GQLVarIdent = new GQLVariable('ident',new GQLVariableType('ID!'));
        Map<String,String> variables = new Map<String,String>{'ident' => ident};
        GQLQuery q = new GQLQuery(
            new GQLOperation(
                new GQLOperationType(GQLOperationType_e.QUERY),
                '', //noname
                new GQLVariableDefinitions().addVariable(GQLVarIdent),
                new GQLSelectionSet().addItem(
                    new GQLField(
                        'hentPerson',
                        new GQLArguments().addArgument(
                            new GQLArgument(
                                'ident',
                                new GQLValue(GQLVarIdent)
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
        return s;
    }
}
