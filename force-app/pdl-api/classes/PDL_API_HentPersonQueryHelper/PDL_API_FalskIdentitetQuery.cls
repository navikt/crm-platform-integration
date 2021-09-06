public with sharing class PDL_API_FalskIdentitetQuery {
    public Boolean erFalsk = false;
    public Boolean rettIdentitetVedIdentifikasjonsnummer = false;
    public Boolean rettIdentitetErUkjent = false;
    public Boolean rettIdentitetVedOpplysninger = false;

    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_FalskIdentitetQuery() {

    }

    public Boolean isEmpty(){
        return !(   erFalsk ||
                    rettIdentitetVedIdentifikasjonsnummer ||
                    rettIdentitetErUkjent ||
                    rettIdentitetVedOpplysninger ||
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( erFalsk ) selectionSet.addItem( new GQLField( 'erFalsk' ) );
        if ( rettIdentitetVedIdentifikasjonsnummer ) selectionSet.addItem( new GQLField( 'rettIdentitetVedIdentifikasjonsnummer' ) );
        if ( rettIdentitetErUkjent ) selectionSet.addItem( new GQLField( 'rettIdentitetErUkjent' ) );
        if ( rettIdentitetVedOpplysninger ) selectionSet.addItem( new GQLField( 'rettIdentitetVedOpplysninger' ) );
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'falskIdentitet',
            args,
            selectionSet
        );
    }
}
