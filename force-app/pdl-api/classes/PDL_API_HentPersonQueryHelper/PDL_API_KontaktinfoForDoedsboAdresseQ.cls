public with sharing class PDL_API_KontaktinfoForDoedsboAdresseQ {

    public Boolean adresselinje1 = false;
    public Boolean adresselinje2 = false;
    public Boolean poststedsnavn = false;
    public Boolean postnummer = false;
    public Boolean landkode = false;

    public PDL_API_KontaktinfoForDoedsboAdresseQ() {

    }

    public void selectAll(){
        adresselinje1 = true;
        adresselinje2 = true;
        poststedsnavn = true;
        postnummer = true;
        landkode = true;
    }

    public Boolean isEmpty(){
        return !(   adresselinje1 ||
                    adresselinje2 ||
                    poststedsnavn ||
                    postnummer ||
                    landkode  );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( adresselinje1 ) selectionSet.addItem( new GQLField( 'adresselinje1' ) );
        if ( adresselinje2 ) selectionSet.addItem( new GQLField( 'adresselinje2' ) );
        if ( poststedsnavn ) selectionSet.addItem( new GQLField( 'poststedsnavn' ) );
        if ( postnummer ) selectionSet.addItem( new GQLField( 'postnummer' ) );
        if ( landkode ) selectionSet.addItem( new GQLField( 'landkode' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'adresse',
            args,
            selectionSet
        );
    }
}
