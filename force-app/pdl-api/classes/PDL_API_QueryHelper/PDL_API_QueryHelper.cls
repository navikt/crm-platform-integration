public with sharing class PDL_API_QueryHelper {
    public PDL_API_HentPersonQuery hentPerson;
    public PDL_API_HentIdenterQuery hentIdenter;
    public PDL_API_HentGeografiskTilknytningQuery hentGeografiskTilknytning;
    GQLVariable varIdent;
    GQLVariable varIdentGrupper;
    Set<PDL_API_IdentGruppeQuery> setIdentGrupper;
    Map<String, Object> variables;
    Boolean includeHentPerson;
    Boolean includeHentIdenter;
    Boolean includeHentGeografiskTilknytning;

    public PDL_API_QueryHelper(String ident) {
        this(ident, true, true, false);
    }

    public PDL_API_QueryHelper(String ident, Boolean includeHentIdenter, Boolean includeHentPerson) {
        this(ident, includeHentIdenter, includeHentPerson, false);
    }

    public PDL_API_QueryHelper(
        String ident,
        Boolean includeHentIdenter,
        Boolean includeHentPerson,
        Boolean includeHentGeografiskTilknytning
    ) {
        varIdent = new GQLVariable('ident', new GQLVariableType('ID!'));
        variables = new Map<String, Object>{ varIdent.getName() => ident };
        hentPerson = new PDL_API_HentPersonQuery(varIdent);
        hentIdenter = new PDL_API_HentIdenterQuery(varIdent);
        hentGeografiskTilknytning = new PDL_API_HentGeografiskTilknytningQuery(varIdent);
        this.includeHentIdenter = includeHentIdenter;
        this.includeHentPerson = includeHentPerson;
        this.includeHentGeografiskTilknytning = includeHentGeografiskTilknytning;
    }

    public void addIdentGruppe(PDL_API_IdentGruppeQuery gruppe) {
        if (setIdentGrupper == null) {
            setIdentGrupper = new Set<PDL_API_IdentGruppeQuery>();
            varIdentGrupper = new GQLVariable('grupper', new GQLVariableType('[IdentGruppe!]'));
            variables.put(varIdentGrupper.getName(), setIdentGrupper);
            hentIdenter.setGrupper(varIdentGrupper);
        }
        setIdentGrupper.add(gruppe);
    }
    public void removeIdentGruppe(PDL_API_IdentGruppeQuery gruppe) {
        if (setIdentGrupper == null)
            return;
        setIdentGrupper.remove(gruppe);
        if (setIdentGrupper.isEmpty()) {
            setIdentGrupper = null;
            variables.remove(varIdentGrupper.getName());
            hentIdenter.setGrupper(varIdentGrupper);
        }
    }

    public void selectAll(Boolean includeMetadata) {
        hentPerson.selectAll(true);
        hentIdenter.selectAll();
        hentGeografiskTilknytning.selectAll();
    }

    public void selectAll() {
        hentPerson.selectAll();
        hentIdenter.selectAll();
        hentGeografiskTilknytning.selectAll();
    }

    public String build() {
        GQLVariableDefinitions pdlVariables = new GQLVariableDefinitions();
        pdlVariables.addVariable(varIdent);
        if (setIdentGrupper != null)
            pdlVariables.addVariable(varIdentGrupper);
        GQLSelectionSet pdlOperations = new GQLSelectionSet();
        if (includeHentPerson) {
            pdlOperations.addItem(hentPerson.buildGQLField());
        }
        if (includeHentIdenter) {
            pdlOperations.addItem(hentIdenter.buildGQLField());
        }
        if (includeHentGeografiskTilknytning) {
            pdlOperations.addItem(hentGeografiskTilknytning.buildGQLField());
        }

        return new GQLQuery(new GQLOperation(new GQLOperationType(), '', pdlVariables, pdlOperations), variables)
            .build();
    }
    public PDL_API_Response execute() {
        return PDL_API_Response.fromHttpResponse(PdlService.queryData(this.build()));
    }
}
