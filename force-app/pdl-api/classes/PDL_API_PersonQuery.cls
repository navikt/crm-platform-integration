public with sharing class PDL_API_PersonQuery {
    GQLVariable ident;
    public PDL_API_NavnQuery navn;
    public PDL_API_ForeldreansvarQuery foreldreansvar;

    public PDL_API_PersonQuery(GQLVariable ident) {
        this.ident = ident;
        navn = new PDL_API_NavnQuery();
        foreldreansvar = new PDL_API_ForeldreansvarQuery();
    }

    public Boolean isEmpty(){
        return ( navn.isEmpty() && foreldreansvar.isEmpty() ) ;
    }

    public GQLField buildGQLField(){
        if(isEmpty() || ident == null) return null;
        
        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( !navn.isEmpty() ) selectionSet.addItem( navn.buildGQLField() );
        if ( !foreldreansvar.isEmpty() ) selectionSet.addItem( foreldreansvar.buildGQLField() );

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
