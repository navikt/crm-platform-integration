public with sharing class PDL_API_SikkerhetstiltakKontaktpersonQ {

    public Boolean personident = false;
    public Boolean enhet = false;

    public PDL_API_SikkerhetstiltakKontaktpersonQ() {

    }

    public void selectAll(){
        personident = true;
        enhet = true;
    }

    public Boolean isEmpty(){
        return !(   personident ||
                    enhet );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( personident ) selectionSet.addItem( new GQLField( 'personident' ) );
        if ( enhet ) selectionSet.addItem( new GQLField( 'enhet' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'kontaktperson',
            args,
            selectionSet
        );
    }
}
