public with sharing class PDL_API_KontaktinfoForDoedsboAdvokatQ {

    PDL_API_PersonnavnQuery personnavn;
    public Boolean organisasjonsnavn = false;
    public Boolean organisasjonsnummer = false;

    public PDL_API_KontaktinfoForDoedsboAdvokatQ() {
        personnavn = new PDL_API_PersonnavnQuery();
    }

    public void selectAll(){
        personnavn.selectAll();
        organisasjonsnavn = true;
        organisasjonsnummer = true;
    }

    public Boolean isEmpty(){
        return !(   !personnavn.isEmpty() || 
        organisasjonsnavn || 
        organisasjonsnummer );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        selectionSet.addItem( personnavn.buildGQLField() );
        if ( organisasjonsnavn ) selectionSet.addItem( new GQLField( 'organisasjonsnavn' ) );
        if ( organisasjonsnummer ) selectionSet.addItem( new GQLField( 'organisasjonsnummer' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'advokatSomKontakt',
            args,
            selectionSet
        );
    }
}
