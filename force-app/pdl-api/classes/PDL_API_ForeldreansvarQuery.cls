public with sharing class PDL_API_ForeldreansvarQuery {
    public Boolean historikk = false;

    public Boolean ansvar = false;
    public Boolean ansvarlig = false;
    public Boolean ansvarssubjekt = false;
    public Boolean ansvarligUtenIdentificator = false;

    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_ForeldreansvarQuery() {

    }

    public Boolean isEmpty(){
        return !(ansvar || ansvarlig || 
                ansvarssubjekt || ansvarligUtenIdentificator);
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( ansvar ) selectionSet.addItem( new GQLField( 'ansvar' ) );
        if ( ansvarlig ) selectionSet.addItem( new GQLField( 'ansvarlig' ) );
        if ( ansvarssubjekt ) selectionSet.addItem( new GQLField( 'ansvarssubjekt' ) );
        if ( ansvarligUtenIdentificator ) selectionSet.addItem( new GQLField( 'ansvarligUtenIdentificator' ) );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'foreldreansvar',
            args,
            selectionSet
        );
    }
}
