public with sharing class PDL_API_PostadresseIFrittFormatQuery {

    public Boolean adresselinje1 = false;
    public Boolean adresselinje2 = false;
    public Boolean adresselinje3 = false;
    public Boolean postnummer = false;

    public PDL_API_PostadresseIFrittFormatQuery() {

    }

    public Boolean isEmpty(){
        return !(   adresselinje1 ||
                    adresselinje2 ||
                    adresselinje3 ||
                    postnummer  );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( adresselinje1 ) selectionSet.addItem( new GQLField( 'adresselinje1' ) );
        if ( adresselinje2 ) selectionSet.addItem( new GQLField( 'adresselinje2' ) );
        if ( adresselinje3 ) selectionSet.addItem( new GQLField( 'adresselinje3' ) );
        if ( postnummer ) selectionSet.addItem( new GQLField( 'postnummer' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'postadresseIFrittFormat',
            args,
            selectionSet
        );
    }
}
