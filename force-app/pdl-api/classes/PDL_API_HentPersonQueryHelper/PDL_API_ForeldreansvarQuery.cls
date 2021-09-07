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

    public void selectAll(){
        ansvar = true;
        ansvarlig = true;
        ansvarssubjekt = true;
        ansvarligUtenIdentificator = true;
    }

    public void selectAll(Boolean metadata){
        if(metadata){
            folkeregistermetadata = true;
            metadata = true;
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   ansvar || 
                    ansvarlig || 
                    ansvarssubjekt || 
                    ansvarligUtenIdentificator || 
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( ansvar ) selectionSet.addItem( new GQLField( 'ansvar' ) );
        if ( ansvarlig ) selectionSet.addItem( new GQLField( 'ansvarlig' ) );
        if ( ansvarssubjekt ) selectionSet.addItem( new GQLField( 'ansvarssubjekt' ) );
        if ( ansvarligUtenIdentificator ) selectionSet.addItem( new GQLField( 'ansvarligUtenIdentificator' ) );
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

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
