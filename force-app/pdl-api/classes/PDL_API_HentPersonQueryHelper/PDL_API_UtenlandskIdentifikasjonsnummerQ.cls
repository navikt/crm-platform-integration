public with sharing class PDL_API_UtenlandskIdentifikasjonsnummerQ {

    public Boolean historikk = false;

    public Boolean identifikasjonsnummer = false;
    public Boolean utstederland = false;
    public Boolean opphoert = false;

    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_UtenlandskIdentifikasjonsnummerQ() {

    }

    public void selectAll(){
        identifikasjonsnummer = true;
        utstederland = true;
        opphoert = true;
    }

    public void selectAll(Boolean metadata){
        if(metadata){
            folkeregistermetadata = true;
            metadata = true;
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   identifikasjonsnummer ||
                    utstederland ||
                    opphoert ||
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( identifikasjonsnummer ) selectionSet.addItem( new GQLField( 'identifikasjonsnummer' ) );
        if ( utstederland ) selectionSet.addItem( new GQLField( 'utstederland' ) );
        if ( opphoert ) selectionSet.addItem( new GQLField( 'opphoert' ) );
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'utenlandskIdentifikasjonsnummer',
            args,
            selectionSet
        );
    }
}
