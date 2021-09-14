public with sharing class PDL_API_HentIdenterQuery {
    GQLVariable identVar;
    GQLVariable grupper;
    public Boolean historikk = false;

    public PDL_API_IdentInformasjonQuery identer;

    public PDL_API_HentIdenterQuery(GQLVariable identVar) {
        this.identVar = identVar;
        identer = new PDL_API_IdentInformasjonQuery();
    }
    public void setGrupper(GQLVariable grupper){
        this.grupper = grupper;
    }

    public void selectAll(){
        identer.selectAll();
    }

    public Boolean isEmpty(){
        return identer.isEmpty();
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        selectionSet.addItem(identer.buildGQLField());

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'ident', new GQLValue(identVar)
            )
        );
        args.addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );
        
        if(grupper != null){
            args.addArgument( 
                new GQLArgument(
                    'grupper', new GQLValue(grupper)
            )
        );
        }

        return new GQLField(
            'hentIdenter',
            args,
            selectionSet
        );
    }
}
