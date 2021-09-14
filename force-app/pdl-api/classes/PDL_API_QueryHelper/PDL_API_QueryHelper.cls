public with sharing class PDL_API_QueryHelper {
    public PDL_API_HentPersonQuery hentPerson;
    public PDL_API_HentIdenterQuery hentIdenter;
    GQLVariable varIdent;
    GQLVariable varIdentGrupper;
    Set<PDL_API_IdentGruppeQuery> setIdentGrupper;
    Map<String,Object> variables;
    public PDL_API_QueryHelper(String ident) {
        varIdent = new GQLVariable('ident',new GQLVariableType('ID!'));
        variables = new Map<String,Object>{ varIdent.getName() => ident };
        hentPerson = new PDL_API_HentPersonQuery(varIdent);
        hentIdenter = new PDL_API_HentIdenterQuery(varIdent);
    }

    public void addIdentGruppe(PDL_API_IdentGruppeQuery gruppe){
        if ( setIdentGrupper == null ){
            setIdentGrupper = new Set<PDL_API_IdentGruppeQuery>();
            varIdentGrupper = new GQLVariable('grupper',new GQLVariableType('[IdentGruppe!]'));
            variables.put(varIdentGrupper.getName(), setIdentGrupper);
            hentIdenter.setGrupper(varIdentGrupper);
        }
        setIdentGrupper.add(gruppe);
    }
    public void removeIdentGruppe(PDL_API_IdentGruppeQuery gruppe){
        if ( setIdentGrupper == null ) return;
        setIdentGrupper.remove(gruppe);
        if (setIdentGrupper.isEmpty()){
            setIdentGrupper = null;
            variables.remove(varIdentGrupper.getName());
            hentIdenter.setGrupper(varIdentGrupper);
        }
        
    }

    public String build(){
        GQLVariableDefinitions pdlVariables = new GQLVariableDefinitions();
        pdlVariables.addVariable(varIdent);
        if( setIdentGrupper != null)
            pdlVariables.addVariable(varIdentGrupper);
        GQLSelectionSet pdlOperations = new GQLSelectionSet();
        pdlOperations.addItem(hentPerson.buildGQLField());
        pdlOperations.addItem(hentIdenter.buildGQLField());

        return new GQLQuery(
            new GQLOperation(
                new GQLOperationType(),
                '',
                pdlVariables,
                pdlOperations
            ),
            variables  
        ).build();
    }
    public PDL_API_Response execute(){
        return PDL_API_Response.fromHttpResponse(PdlService.queryData(this.build()));
    }
    
}
