public with sharing class PDL_API_TjenesteomraadeQuery {
    
    public Boolean tjenesteoppgave = false;
    public Boolean tjenestevirksomhet = false;
    
    public PDL_API_TjenesteomraadeQuery() {
    }

    public void selectAll(){
        tjenesteoppgave = true;
        tjenestevirksomhet = true;
    }

    public Boolean isEmpty(){
        return !(   tjenesteoppgave ||
                    tjenestevirksomhet);
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( tjenesteoppgave ) selectionSet.addItem( new GQLField( 'tjenesteoppgave' ) );
        if ( tjenestevirksomhet ) selectionSet.addItem( new GQLField( 'tjenestevirksomhet' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'tjenesteomraade',
            args,
            selectionSet
        );
    }
}
