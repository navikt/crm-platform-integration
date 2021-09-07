public with sharing class PDL_API_KontaktinfoForDoedsboOrgQ {

    public Boolean kontaktperson = false;
    public Boolean organisasjonsnavn = false;
    public Boolean organisasjonsnummer = false;

    public PDL_API_KontaktinfoForDoedsboOrgQ() {

    }

    public void selectAll(){
        kontaktperson = true;
        organisasjonsnavn = true;
        organisasjonsnummer = true;
    }

    public Boolean isEmpty(){
        return !(   kontaktperson || 
        organisasjonsnavn || 
        organisasjonsnummer );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( kontaktperson ) selectionSet.addItem( new GQLField( 'kontaktperson' ) );
        if ( organisasjonsnavn ) selectionSet.addItem( new GQLField( 'organisasjonsnavn' ) );
        if ( organisasjonsnummer ) selectionSet.addItem( new GQLField( 'organisasjonsnummer' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'organisasjonSomKontakt',
            args,
            selectionSet
        );
    }
}
