public with sharing class PDL_API_KontaktinfoForDoedsboAdvokatQ {

    public Boolean personnavn = false;
    public Boolean organisasjonsnavn = false;
    public Boolean organisasjonsnummer = false;

    public PDL_API_KontaktinfoForDoedsboAdvokatQ() {

    }

    public void selectAll(){
        personnavn = true;
        organisasjonsnavn = true;
        organisasjonsnummer = true;
    }

    public Boolean isEmpty(){
        return !(   personnavn || 
        organisasjonsnavn || 
        organisasjonsnummer );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( personnavn ) selectionSet.addItem( new GQLField( 'personnavn' ) );
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
