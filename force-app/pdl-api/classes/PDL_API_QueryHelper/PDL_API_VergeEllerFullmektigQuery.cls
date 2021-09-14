public with sharing class PDL_API_VergeEllerFullmektigQuery {
    
    PDL_API_PersonnavnQuery navn;
    public Boolean motpartsPersonident = false;
    public Boolean omfang = false;
    public Boolean omfangetErInnenPersonligOmraade = false;
    
    public PDL_API_VergeEllerFullmektigQuery() {
        navn = new PDL_API_PersonnavnQuery('navn');
    }

    public void selectAll(){
        navn.selectAll();
        motpartsPersonident = true;
        omfang = true;
        omfangetErInnenPersonligOmraade = true;
    }

    public Boolean isEmpty(){
        return !(   !navn.isEmpty() ||
                    motpartsPersonident ||
                    omfang ||
                    omfangetErInnenPersonligOmraade );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        selectionSet.addItem( navn.buildGQLField() );
        if ( motpartsPersonident ) selectionSet.addItem( new GQLField( 'motpartsPersonident' ) );
        if ( omfang ) selectionSet.addItem( new GQLField( 'omfang' ) );
        if ( omfangetErInnenPersonligOmraade ) selectionSet.addItem( new GQLField( 'omfangetErInnenPersonligOmraade' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'vergeEllerFullmektig',
            args,
            selectionSet
        );
    }
}
