public with sharing class PDL_API_KontaktinfoForDoedsboPersonQ {

    public Boolean foedselsdato = false;
    public Boolean personnavn = false;
    public Boolean identifikasjonsnummer = false;

    public PDL_API_KontaktinfoForDoedsboPersonQ() {

    }

    public Boolean isEmpty(){
        return !(   foedselsdato || 
                    personnavn || 
                    identifikasjonsnummer );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( foedselsdato ) selectionSet.addItem( new GQLField( 'foedselsdato' ) );
        if ( personnavn ) selectionSet.addItem( new GQLField( 'personnavn' ) );
        if ( identifikasjonsnummer ) selectionSet.addItem( new GQLField( 'identifikasjonsnummer' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'personSomKontakt',
            args,
            selectionSet
        );
    }
}
