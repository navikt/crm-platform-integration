public with sharing class PDL_API_KontaktinfoForDoedsboPersonQ {

    public Boolean foedselsdato = false;
    PDL_API_PersonnavnQuery personnavn;
    public Boolean identifikasjonsnummer = false;

    public PDL_API_KontaktinfoForDoedsboPersonQ() {
        personnavn = new PDL_API_PersonnavnQuery();
    }

    public void selectAll(){
        foedselsdato = true;
        personnavn.selectAll();
        identifikasjonsnummer = true;
    }

    public Boolean isEmpty(){
        return !(   foedselsdato || 
                    !personnavn.isEmpty() || 
                    identifikasjonsnummer );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( foedselsdato ) selectionSet.addItem( new GQLField( 'foedselsdato' ) );
        selectionSet.addItem( personnavn.buildGQLField() );
        if ( identifikasjonsnummer ) selectionSet.addItem( new GQLField( 'identifikasjonsnummer' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'personSomKontakt',
            args,
            selectionSet
        );
    }
}
