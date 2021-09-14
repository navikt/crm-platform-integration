public with sharing class PDL_API_IdentInformasjonQuery {

    public Boolean ident = false;
    public Boolean gruppe = false;
    public Boolean historisk = false;

    public PDL_API_IdentInformasjonQuery() {}

    public void selectAll(){
        ident = true;
        gruppe = true;
        historisk = true;
    }
    public Boolean isEmpty(){
        return !(   ident || 
                    gruppe || 
                    historisk );
    }
    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( ident ) selectionSet.addItem( new GQLField( 'ident' ) );
        if ( gruppe ) selectionSet.addItem( new GQLField( 'gruppe' ) );
        if ( historisk ) selectionSet.addItem( new GQLField( 'historisk' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'identer',
            args,
            selectionSet
        );
    }
}
