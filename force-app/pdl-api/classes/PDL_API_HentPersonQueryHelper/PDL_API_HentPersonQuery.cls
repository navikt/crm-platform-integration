public with sharing class PDL_API_HentPersonQuery {
    public PDL_API_PersonQuery hentPerson;
    GQLVariable varIdent;
    Map<String,String> variables;
    public PDL_API_HentPersonQuery(String ident) {
        varIdent = new GQLVariable('ident',new GQLVariableType('ID!'));
        variables = new Map<String,String>{ varIdent.getName() => ident };
        hentPerson = new PDL_API_PersonQuery(varIdent);
    }
    public void setIdent(String ident){
        variables = new Map<String,String>{ varIdent.getName() => ident};
    }
    public String build(){
        return new GQLQuery(
            new GQLOperation(
                new GQLOperationType(),
                '',
                new GQLVariableDefinitions().addVariable(varIdent),
                new GQLSelectionSet().addItem(hentPerson.buildGQLField())
            ),
            variables  
        ).build();
    }
}
