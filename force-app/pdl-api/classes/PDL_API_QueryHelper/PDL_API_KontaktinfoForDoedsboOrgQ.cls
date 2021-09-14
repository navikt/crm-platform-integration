public with sharing class PDL_API_KontaktinfoForDoedsboOrgQ {

    PDL_API_PersonnavnQuery kontaktperson;
    public Boolean organisasjonsnavn = false;
    public Boolean organisasjonsnummer = false;

    public PDL_API_KontaktinfoForDoedsboOrgQ() {
        kontaktperson = new PDL_API_PersonnavnQuery('kontaktperson');
    }

    public void selectAll(){
        kontaktperson.selectAll();
        organisasjonsnavn = true;
        organisasjonsnummer = true;
    }

    public Boolean isEmpty(){
        return !(   !kontaktperson.isEmpty() || 
        organisasjonsnavn || 
        organisasjonsnummer );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        selectionSet.addItem( kontaktperson.buildGQLField() );
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
